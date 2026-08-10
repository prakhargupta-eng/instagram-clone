import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart' as video;

import '../../constants.dart';
import '../../models/post.dart';
import '../../models/story.dart';
import '../../models/user.dart';
import '../../services/feed_service.dart';
import '../../services/local_post_store.dart';
import '../../widgets/media_image.dart';
import 'post_editor_screen.dart';
import 'location_picker_sheet.dart';
import 'music_picker_sheet.dart';

class _MediaSelection {
  const _MediaSelection({
    required this.url,
    required this.thumbnail,
    required this.isVideo,
  });

  final String url;
  final String thumbnail;
  final bool isVideo;
}

const _mockVideos = <(String, String)>[
  (
    'https://test-videos.co.uk/vids/sintel/mp4/h264/720/Sintel_720_10s_1MB.mp4',
    'https://picsum.photos/seed/vpick1/400/600',
  ),
  (
    'https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4',
    'https://picsum.photos/seed/vpick2/400/600',
  ),
  (
    'https://test-videos.co.uk/vids/jellyfish/mp4/h264/360/Jellyfish_360_10s_1MB.mp4',
    'https://picsum.photos/seed/vpick3/400/600',
  ),
  (
    'https://test-videos.co.uk/vids/elephantsdream/mp4/h264/360/ElephantsDream_360_10s_1MB.mp4',
    'https://picsum.photos/seed/vpick4/400/600',
  ),
  (
    'https://test-videos.co.uk/vids/caminandes/mp4/h264/360/Caminandes_360_10s_1MB.mp4',
    'https://picsum.photos/seed/vpick5/400/600',
  ),
  (
    'https://www.w3schools.com/html/mov_bbb.mp4',
    'https://picsum.photos/seed/vpick6/400/600',
  ),
  (
    'https://media.w3.org/2010/05/sintel/trailer.mp4',
    'https://picsum.photos/seed/vpick7/400/600',
  ),
];

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
  List<AssetEntity> _assets = const [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadGallery();
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

    String thumb = edited;
    if (isVideo) {
      (String, String)? match;
      for (final item in _mockVideos) {
        if (item.$1 == url) {
          match = item;
          break;
        }
      }
      if (match != null) {
        thumb = match.$2;
      } else {
        thumb = 'https://picsum.photos/seed/vid_${DateTime.now().millisecondsSinceEpoch}/600/600';
      }
    }

    setState(() {
      _selected = _MediaSelection(
        url: edited,
        thumbnail: thumb,
        isVideo: isVideo,
      );
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 2048,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;
    await _openEditor(url: picked.path, isVideo: false);
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picked = await _imagePicker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 60),
    );
    if (picked == null || !mounted) return;
    await _openEditor(url: picked.path, isVideo: true);
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
        createdAt: DateTime.now(),
        isVideo: selection.isVideo,
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
        backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          _selected == null ? 'New Post' : 'New Post',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: _selected == null
            ? IconButton(
                icon: const Icon(Icons.close, size: 26),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary,
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
          child: Container(color: AppColors.border, height: 0.5),
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
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Recents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.expand_more,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        _HeaderChip(
                          icon: Icons.camera_alt_outlined,
                          label: 'Camera',
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                        const SizedBox(width: 8),
                        _HeaderChip(
                          icon: Icons.videocam_outlined,
                          label: 'Record Video',
                          onTap: () => _pickVideo(ImageSource.camera),
                        ),
                        const SizedBox(width: 8),
                        _HeaderChip(
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
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _galleryError!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
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
                    return _GalleryThumbnail(
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

        // ── Videos section ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 20, 14, 10),
                child: Text(
                  'Videos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(
                height: 124,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final (videoUrl, thumbnail) in _mockVideos)
                      GestureDetector(
                        onTap: () => _openEditor(url: videoUrl, isVideo: true),
                        child: Container(
                          width: 100,
                          height: 124,
                          margin: const EdgeInsets.only(right: 8),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: AppColors.border,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(imageUrl: thumbnail, fit: BoxFit.cover),
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black54,
                                    ],
                                  ),
                                ),
                              ),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                              const Positioned(
                                bottom: 6,
                                right: 6,
                                child: Icon(
                                  Icons.videocam_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
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
              _AvatarSmall(url: widget.currentUser.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _captionController,
                  maxLines: 5,
                  minLines: 2,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Write a caption...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
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
                            CachedNetworkImage(
                              imageUrl: selection.thumbnail,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.border,
                                child: const Icon(
                                  Icons.play_circle_outline,
                                  color: AppColors.textSecondary,
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
                      : MediaImage(path: selection.thumbnail, fit: BoxFit.cover),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 0.5, thickness: 0.5, color: AppColors.border),

        // ── Tag / Location options ───────────────────────────────────
        _CaptionOption(
          icon: Icons.person_outline,
          label: 'Tag people',
          onTap: () {},
        ),
        const Divider(height: 0.5, thickness: 0.5, color: AppColors.border),
        if (_location != null)
          _CaptionOption(
            icon: Icons.location_on,
            label: _location!,
            trailing: IconButton(
              icon: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _location = null),
            ),
            onTap: _pickLocation,
          ),
        if (_location == null)
          _CaptionOption(
            icon: Icons.location_on_outlined,
            label: 'Add location',
            onTap: _pickLocation,
          ),
        const Divider(height: 0.5, thickness: 0.5, color: AppColors.border),
        if (_music != null)
          _CaptionOption(
            icon: Icons.music_note,
            label: _music!,
            trailing: IconButton(
              icon: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() {
                _music = null;
                _musicPreviewUrl = null;
              }),
            ),
            onTap: _pickMusic,
          ),
        if (_music == null)
          _CaptionOption(
            icon: Icons.music_note_outlined,
            label: 'Add music',
            onTap: _pickMusic,
          ),
        const Divider(height: 0.5, thickness: 0.5, color: AppColors.border),
      ],
    );
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({required this.url});

  final String url;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  video.VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final path = widget.url;
    _controller =
        LocalPostStore.isLocalPath(path)
              ? video.VideoPlayerController.file(File(path))
              : video.VideoPlayerController.networkUrl(Uri.parse(path))
          ..initialize()
              .then((_) {
                if (!mounted) return;
                _controller?.setLooping(true);
                _controller?.setVolume(0);
                _controller?.play();
                setState(() {});
              })
              .catchError((_) {
                if (!mounted) return;
                setState(() {});
              });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: AppColors.background,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return video.VideoPlayer(controller);
  }
}

// ── Header action chip ────────────────────────────────────────────────────────

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryThumbnail extends StatelessWidget {
  const _GalleryThumbnail({required this.asset, required this.onTap});

  final AssetEntity asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isVideo = asset.type == AssetType.video;
    return GestureDetector(
      onTap: onTap,
      child: FutureBuilder<Uint8List?>(
        future: asset.thumbnailDataWithSize(const ThumbnailSize(600, 600)),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return Container(
              color: AppColors.background,
              alignment: Alignment.center,
              child: Icon(
                isVideo ? Icons.movie_outlined : Icons.image_outlined,
                color: AppColors.textSecondary,
              ),
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(data, fit: BoxFit.cover),
              if (isVideo)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AvatarSmall extends StatelessWidget {
  const _AvatarSmall({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 32,
        height: 32,
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const _FallbackAvatar(),
              )
            : const _FallbackAvatar(),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: AppColors.surface, size: 18),
    );
  }
}

// ── Caption option row ────────────────────────────────────────────────────────

class _CaptionOption extends StatelessWidget {
  const _CaptionOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
          ],
        ),
      ),
    );
  }
}
