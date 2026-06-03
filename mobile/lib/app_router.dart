import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/lists/screens/lists_screen.dart';
import 'features/lists/screens/list_detail_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/detail/providers/detail_provider.dart';
import 'features/detail/providers/season_provider.dart';
import 'features/detail/screens/detail_screen.dart';
import 'features/home/screens/popular_screen.dart';
import 'features/admin/screens/admin_users_screen.dart';
import 'features/person/providers/person_provider.dart';
import 'features/person/screens/person_screen.dart';
import 'shared/widgets/main_scaffold.dart';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final isAuth = state.uri.path == '/login' || state.uri.path == '/register';
      if (!loggedIn && !isAuth) return '/login';
      if (loggedIn && isAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/home'),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(path: '/lists', builder: (_, __) => const ListsScreen()),
          GoRoute(
            path: '/lists/:id',
            builder: (_, state) =>
                ListDetailScreen(listId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/popular',
        builder: (_, __) => const PopularScreen(),
      ),
      GoRoute(
        path: '/detail/:tmdbId',
        builder: (_, state) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => DetailProvider()),
            ChangeNotifierProvider(create: (_) => SeasonProvider()),
          ],
          child: DetailScreen(
            tmdbId: int.parse(state.pathParameters['tmdbId']!),
            mediaType: state.uri.queryParameters['type'] ?? 'movie',
            title: state.uri.queryParameters['title'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (_, __) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/person/:personId',
        builder: (_, state) => ChangeNotifierProvider(
          create: (_) => PersonProvider(),
          child: PersonScreen(
            personId: int.parse(state.pathParameters['personId']!),
            name: state.uri.queryParameters['name'] ?? '',
          ),
        ),
      ),
    ],
  );
}
