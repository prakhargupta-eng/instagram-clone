import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart' as video;

import '../../constants.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../../services/feed_service.dart';
import '../../services/local_post_store.dart';
import '../../widgets/media_image.dart';
import 'post_editor_screen.dart';

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
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'https://picsum.photos/seed/vpick1/400/600',
  ),
  (
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    'https://picsum.photos/seed/vpick2/400/600',
  ),
  (
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
    'https://picsum.photos/seed/vpick3/400/600',
  ),
];

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
    required this.feedService,
    required this.currentUser,
  });

  final FeedService feedService;
  final AppUser currentUser;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  _MediaSelection? _selected;
  final _captionController = TextEditingController();
  bool _sharing = false;
  bool _loadingGallery = true;
  String? _galleryError;
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
        type: RequestType.image,
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
    setState(() {
      _selected = _MediaSelection(
        url: edited,
        thumbnail: isVideo ? url : edited,
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

  Future<void> _pickFromGalleryAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null || !mounted) return;
    await _openEditor(url: file.path, isVideo: false);
  }

  void _share() {
    setState(() => _sharing = true);
    Future.delayed(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      final selection = _selected!;
      final post = Post(
        id: 'p${DateTime.now().millisecondsSinceEpoch}',
        author: widget.currentUser,
        imageUrl: selection.thumbnail,
        videoUrl: selection.isVideo ? selection.url : '',
        caption: _captionController.text.trim(),
        createdAt: DateTime.now(),
        isVideo: selection.isVideo,
      );
      widget.feedService.addPost(post);
      await LocalPostStore.instance.add(post);
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          AppStrings.newPost,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: _selected == null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Text(AppStrings.share),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _selected == null ? _buildPicker() : _buildCaption(),
    );
  }

  Widget _buildPicker() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: _loadingGallery ? 1 : _assets.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _Tile(
                child: Container(
                  color: AppColors.background,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_camera_outlined, color: AppColors.textSecondary, size: 32),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.takePhoto,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                onTap: () => _pickImage(ImageSource.camera),
              );
            }
            if (_loadingGallery) {
              return Container(
                color: AppColors.background,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (_galleryError != null && _assets.isEmpty) {
              return Container(
                color: AppColors.background,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                child: Text(
                  _galleryError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              );
            }
            final asset = _assets[index - 1];
            return _GalleryThumbnail(
              asset: asset,
              onTap: () => _pickFromGalleryAsset(asset),
            );
          },
        ),
        if (_galleryError != null && _assets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              _galleryError!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
          child: Text(
            'Videos',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final (videoUrl, thumbnail) in _mockVideos)
                GestureDetector(
                  onTap: () => _openEditor(url: videoUrl, isVideo: true),
                  child: Container(
                    width: 100,
                    height: 120,
                    margin: const EdgeInsets.only(right: 8),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.border,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(thumbnail, fit: BoxFit.cover),
                        Container(
                          color: Colors.black38,
                          alignment: Alignment.center,
                          child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                  ),
                ),
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
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: selection.isVideo
                    ? _VideoPreview(url: selection.url)
                    : MediaImage(
                        path: selection.thumbnail,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.border,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary, size: 40),
                        ),
                      ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarSmall(url: widget.currentUser.avatarUrl),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _captionController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: AppStrings.writeCaption,
                    filled: false,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
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
    _controller = video.VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        _controller?.setLooping(true);
        _controller?.setVolume(0);
        _controller?.play();
        setState(() {});
      }).catchError((_) {
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

class _Tile extends StatelessWidget {
  const _Tile({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }
}

class _GalleryThumbnail extends StatelessWidget {
  const _GalleryThumbnail({required this.asset, required this.onTap});

  final AssetEntity asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
            );
          }
          return Image.memory(data, fit: BoxFit.cover);
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
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _FallbackAvatar(),
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
