import 'package:flutter/material.dart';
import '../../adaptive_colors.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/feed_service.dart';
import '../create/create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../reels/reels_screen.dart';
import '../search/search_screen.dart';
import 'home_screen.dart';
import '../../widgets/avatar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.authService});

  final AuthService authService;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final FeedService _feedService = FeedService();
  int _selectedIndex = 0;

  AppUser get _currentUser => widget.authService.currentUser!;

  @override
  void initState() {
    super.initState();
    final user = widget.authService.currentUser;
    if (user != null) {
      _feedService.ensureLocalPostsLoaded(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.authService.currentUser == null) {
      return Scaffold(backgroundColor: context.surfaceColor);
    }
    // _selectedIndex: 0=home, 1=search, 3=reels, 4=profile
    // screens list:  [0=Home, 1=Search, 2=Reels, 3=Profile]
    final screenIndex = switch (_selectedIndex) {
      0 => 0,
      1 => 1,
      3 => 2, // Reels
      4 => 3, // Profile
      _ => 0,
    };

    final screens = [
      HomeScreen(
        authService: widget.authService,
        feedService: _feedService,
        visible: screenIndex == 0,
      ),
      SearchScreen(feedService: _feedService, authService: widget.authService),
      ReelsScreen(
        feedService: _feedService,
        currentUser: _currentUser,
        visible: screenIndex == 2,
      ),
      ProfileScreen(feedService: _feedService, user: _currentUser, authService: widget.authService),
    ];
    return Scaffold(
      body: IndexedStack(index: screenIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(top: BorderSide(color: context.borderColor, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: 'assets/icons/home.png',
                  selectedIcon: 'assets/icons/home.png',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onDestinationSelected(0),
                ),
                _NavItem(
                  icon: 'assets/icons/search.png',
                  selectedIcon: 'assets/icons/search.png',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onDestinationSelected(1),
                ),
                _NavItem(
                  icon: 'assets/icons/add.png',
                  selectedIcon: 'assets/icons/add.png',
                  isSelected: false,
                  onTap: () => _onDestinationSelected(2),
                ),
                _NavItem(
                  icon: 'assets/icons/reels.png',
                  selectedIcon: 'assets/icons/reels.png',
                  isSelected: _selectedIndex == 3,
                  onTap: () => _onDestinationSelected(3),
                ),
                // Profile avatar as last nav item
                GestureDetector(
                  onTap: () => _onDestinationSelected(4),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 48,
                    alignment: Alignment.center,
                    child: Container(
                      padding: _selectedIndex == 4 ? const EdgeInsets.all(2) : EdgeInsets.zero,
                      decoration: _selectedIndex == 4
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: context.textPrimaryColor, width: 2),
                            )
                          : null,
                      child: Avatar(
                        url: _currentUser.avatarUrl,
                        radius: 14,
                        showRing: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onDestinationSelected(int index) {
    if (index == 2) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: context.surfaceColor,
        builder: (_) => CreatePostScreen(
          feedService: _feedService,
          currentUser: _currentUser,
        ),
      );
      return;
    }
    // Store raw nav index: 0=home, 1=search, 3=reels, 4=profile
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedIndex = index);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String icon;
  final String selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? context.textPrimaryColor : context.textSecondaryColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 52,
        child: Center(
          child: Image.asset(
            isSelected ? selectedIcon : icon,
            width: 20,
            height: 20,
            color: color,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (_, _, _) => Icon(
              Icons.search_outlined,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
