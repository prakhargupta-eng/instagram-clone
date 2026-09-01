import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:get_thumbnail_video/index.dart';

import '../../adaptive_colors.dart';
import '../../constants.dart';
import '../../models/post.dart';
import '../../models/story.dart';
import '../../models/user.dart';
import '../../services/feed_service.dart';
import '../../widgets/media_image.dart';
import '../../components/ToastHelper.dart';
import 'post_editor_screen.dart';
import 'location_picker_sheet.dart';
import 'music_picker_sheet.dart';
import 'tag_people_sheet.dart';
import 'components/caption_option.dart';
import 'components/create_post_helpers.dart';
import 'components/gallery_thumbnail.dart';

class _MediaSelection {
  const _MediaSelection({
    required this.url,
    required this.thumbnail,
    required this.isVideo,
    this.filterIndex = 0,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
  });

  final String url;
  final String thumbnail;
  final bool isVideo;
  final int filterIndex;
  final double brightness;
  final double contrast;
  final double saturation;
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    required this.feedService,
    required this.currentUser,
    this.isStory = false,
  });

  final FeedService feedService;
  final AppUser currentUser;
  final bool isStory;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  _MediaSelection? _selected;
  final _captionController = TextEditingController();
  bool _sharing = false;
  bool _loadingGallery = true;
  String? _galleryError;
  String? _location;
  String? _music;
  String? _musicPreviewUrl;
  List<AppUser> _taggedPeople = [];
  List<AssetEntity> _assets = const [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadGallery();
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    try {
      final response = await _imagePicker.retrieveLostData();
      if (response.isEmpty) return;
      final file = response.file;
      if (file != null && mounted) {
        final isVideo = response.type == RetrieveType.video;
        await _openEditor(url: file.path, isVideo: isVideo);
      }
    } catch (e) {
      debugPrint('Error retrieving lost data: $e');
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadGallery() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.hasAccess) {
        setState(() {
          _loadingGallery = false;
          _galleryError = 'Photo access denied';
        });
        return;
      }
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: true,
      );
      if (albums.isEmpty) {
        setState(() {
          _loadingGallery = false;
          _galleryError = 'No photos found';
        });
        return;
      }
      final assets = await albums.first.getAssetListPaged(page: 0, size: 60);
      if (!mounted) return;
      setState(() {
        _assets = assets;
        _loadingGallery = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingGallery = false;
        _galleryError = 'Failed to load photos';
      });
    }
  }

  Future<void> _openEditor({required String url, required bool isVideo}) async {
    final edited = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PostEditorScreen(mediaUrl: url, isVideo: isVideo),
      ),
    );
    if (edited == null || !mounted) return;

    int filterIndex = 0;
    double brightness = 0.0;
    double contrast = 1.0;
    double saturation = 1.0;
    String finalUrl = edited;
    String? returnedThumbnail;

    if (isVideo) {
      try {
        final uri = Uri.parse(edited);
        final cleanUri = uri.replace(queryParameters: {});
        finalUrl = cleanUri.scheme == 'file'
            ? cleanUri.toFilePath()
            : cleanUri.toString();
        final q = uri.queryParameters;
        if (q.containsKey('filterIndex')) {
          filterIndex = int.tryParse(q['filterIndex']!) ?? 0;
        }
        if (q.containsKey('brightness')) {
          brightness = double.tryParse(q['brightness']!) ?? 0.0;
        }
        if (q.containsKey('contrast')) {
          contrast = double.tryParse(q['contrast']!) ?? 1.0;
        }
        if (q.containsKey('saturation')) {
          saturation = double.tryParse(q['saturation']!) ?? 1.0;
        }
        if (q.containsKey('thumbnailPath')) {
          returnedThumbnail = q['thumbnailPath'];
        }
      } catch (_) {}
    }

    String thumb = finalUrl;
    if (isVideo) {
      if (returnedThumbnail != null && returnedThumbnail.isNotEmpty) {
        thumb = returnedThumbnail;
      } else {
        try {
          final tempDir = await getTemporaryDirectory();
          final xFile = await VideoThumbnail.thumbnailFile(
            video: finalUrl,
            thumbnailPath: tempDir.path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 600,
            quality: 75,
          );
          thumb = (xFile as String?) ?? finalUrl;
        } catch (_) {
          thumb =
              'https://picsum.photos/seed/vid_${DateTime.now().millisecondsSinceEpoch}/600/600';
        }
      }
    }

    setState(() {
      _selected = _MediaSelection(
        url: finalUrl,
        thumbnail: thumb,
        isVideo: isVideo,
        filterIndex: filterIndex,
        brightness: brightness,
        contrast: contrast,
        saturation: saturation,
      );
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2048,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;
      await _openEditor(url: picked.path, isVideo: false);
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        String errMsg = 'Error picking image';
        if (e is PlatformException) {
          if (e.code == 'camera_access_denied') {
            errMsg = 'Camera permission is required to take photos.';
          } else {
            errMsg = e.message ?? e.toString();
          }
        } else {
          errMsg = e.toString();
        }
        ToastHelper.showToast(context, errMsg, isError: true);
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );
      if (picked == null || !mounted) return;
      await _openEditor(url: picked.path, isVideo: true);
    } catch (e) {
      debugPrint('Error picking video: $e');
      if (mounted) {
        String errMsg = 'Error picking video';
        if (e is PlatformException) {
          if (e.code == 'camera_access_denied') {
            errMsg = 'Camera permission is required to record video.';
          } else {
            errMsg = e.message ?? e.toString();
          }
        } else {
          errMsg = e.toString();
        }
        ToastHelper.showToast(context, errMsg, isError: true);
      }
    }
  }

  Future<void> _pickFromGalleryAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null || !mounted) return;
    final isVideo = asset.type == AssetType.video;
    await _openEditor(url: file.path, isVideo: isVideo);
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    if (result != null && mounted) setState(() => _location = result);
  }

  Future<void> _pickMusic() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (_) => const MusicPickerScreen()),
    );
    if (result != null && mounted) {
      if (result is Map) {
        setState(() {
          _music = result['name'] as String?;
          _musicPreviewUrl = result['previewUrl'] as String?;
        });
      } else if (result is String) {
        setState(() => _music = result);
      }
    }
  }

  Future<void> _pickTaggedPeople() async {
    final result = await showModalBottomSheet<List<AppUser>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => TagPeopleSheet(initialTagged: _taggedPeople),
    );
    if (result != null && mounted) {
      setState(() => _taggedPeople = result);
    }
  }

  void _share() {
    final selection = _selected!;
    final previewImage = selection.thumbnail;
    if (widget.isStory) {
      setState(() => _sharing = true);
      Future.delayed(const Duration(milliseconds: 400), () async {
        if (!mounted) return;
        final story = Story(
          id: 's${DateTime.now().millisecondsSinceEpoch}',
          user: widget.currentUser,
          imageUrl: selection.isVideo ? selection.url : selection.thumbnail,
          isVideo: selection.isVideo,
          createdAt: DateTime.now(),
        );
        widget.feedService.addStory(story);
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    } else {
      final post = Post(
        id: 'p${DateTime.now().millisecondsSinceEpoch}',
        author: widget.currentUser,
        imageUrl: previewImage,
        videoUrl: selection.isVideo ? selection.url : '',
        caption: _captionController.text.trim(),
        location: _location,
        music: _music,
        musicPreviewUrl: _musicPreviewUrl,
        taggedUsers: _taggedPeople,
        createdAt: DateTime.now(),
        isVideo: selection.isVideo,
        filterIndex: selection.filterIndex,
        brightness: selection.brightness,
        contrast: selection.contrast,
        saturation: selection.saturation,
      );
      Navigator.of(context).pop();
      widget.feedService.startPostUpload(post);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.surfaceColor,
        appBar: AppBar(
          backgroundColor: context.surfaceColor,
          foregroundColor: context.textPrimaryColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            _selected == null ? 'New Post' : 'New Post',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
          leading: _selected == null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 26),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              : IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: context.textPrimaryColor,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _selected = null),
                ),
          actions: [
            if (_selected != null)
              TextButton(
                onPressed: _sharing ? null : _share,
                child: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text(
                        'Share',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Container(color: context.borderColor, height: 0.5),
          ),
        ),
        body: _selected == null ? _buildPicker() : _buildCaption(),
      ),
    );
  }

  Widget _buildPicker() {
    return CustomScrollView(
      slivers: [
        // ── Recents header ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: context.surfaceColor,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Recents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more,
                      size: 20,
                      color: context.textPrimaryColor,
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        HeaderChip(
                          icon: Icons.camera_alt_outlined,
                          label: 'Camera',
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                        const SizedBox(width: 8),
                        HeaderChip(
                          icon: Icons.videocam_outlined,
                          label: 'Record Video',
                          onTap: () => _pickVideo(ImageSource.camera),
                        ),
                        const SizedBox(width: 8),
                        HeaderChip(
                          icon: Icons.video_library_outlined,
                          label: 'Upload Video',
                          onTap: () => _pickVideo(ImageSource.gallery),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Photo grid ──────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(1),
          sliver: _loadingGallery
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : _galleryError != null && _assets.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 48,
                          color: context.textSecondaryColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _galleryError!,
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final asset = _assets[index];
                    return GalleryThumbnail(
                      asset: asset,
                      onTap: () => _pickFromGalleryAsset(asset),
                    );
                  }, childCount: _assets.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 1.5,
                    crossAxisSpacing: 1.5,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCaption() {
    final selection = _selected!;
    return Column(
      children: [
        // ── Caption row ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarSmall(url: widget.currentUser.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _captionController,
                  maxLines: 5,
                  minLines: 2,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 15,
                    color: context.textPrimaryColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write a caption...',
                    hintStyle: TextStyle(color: context.textSecondaryColor),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: selection.isVideo
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            MediaImage(
                              path: selection.thumbnail,
                              videoUrl: selection.url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: context.borderColor,
                                child: Icon(
                                  Icons.play_circle_outline,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ),
                            const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        )
                      : MediaImage(
                          path: selection.thumbnail,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Divider(height: 0.5, thickness: 0.5, color: context.borderColor),

        if (_taggedPeople.isNotEmpty)
          CaptionOption(
            icon: Icons.person,
            label: _taggedPeople.map((u) => '@${u.username}').join(', '),
            trailing: IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: context.textSecondaryColor,
              ),
              onPressed: () => setState(() => _taggedPeople.clear()),
            ),
            onTap: _pickTaggedPeople,
          )
        else
          CaptionOption(
            icon: Icons.person_outline,
            label: 'Tag people',
            onTap: _pickTaggedPeople,
          ),
        Divider(height: 0.5, thickness: 0.5, color: context.borderColor),
        if (_location != null)
          CaptionOption(
            icon: Icons.location_on,
            label: _location!,
            trailing: IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: context.textSecondaryColor,
              ),
              onPressed: () => setState(() => _location = null),
            ),
            onTap: _pickLocation,
          ),
        if (_location == null)
          CaptionOption(
            icon: Icons.location_on_outlined,
            label: 'Add location',
            onTap: _pickLocation,
          ),
        Divider(height: 0.5, thickness: 0.5, color: context.borderColor),
        if (_music != null)
          CaptionOption(
            icon: Icons.music_note,
            label: _music!,
            trailing: IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: context.textSecondaryColor,
              ),
              onPressed: () => setState(() {
                _music = null;
                _musicPreviewUrl = null;
              }),
            ),
            onTap: _pickMusic,
          ),
        if (_music == null)
          CaptionOption(
            icon: Icons.music_note_outlined,
            label: 'Add music',
            onTap: _pickMusic,
          ),
        Divider(height: 0.5, thickness: 0.5, color: context.borderColor),
      ],
    );
  }
}
