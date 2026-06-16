import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'core/navigation/app_route_observer.dart';
import 'core/utils/route_args.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/chat_list/chat_list_screen.dart';
import 'presentation/screens/chat_detail/chat_detail_screen.dart';
import 'presentation/screens/create_group/create_group_screen.dart';
import 'presentation/screens/search/search_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/user_detail/user_detail_screen.dart';
import 'presentation/screens/status/status_screen.dart';
import 'presentation/screens/call/call_screen.dart';
import 'presentation/screens/call_history/call_history_screen.dart';
import 'domain/entities/call_session.dart';
import 'presentation/state/chat_list_cubit.dart';
import 'presentation/state/group_cubit.dart';
import 'presentation/state/profile_cubit.dart';
import 'presentation/state/settings_cubit.dart';
import 'services/local_notification_service.dart';
import 'services/notification_sound_service.dart';
import 'data/database/app_database.dart';

class OmarChatApp extends StatefulWidget {
  const OmarChatApp({super.key});

  @override
  State<OmarChatApp> createState() => _OmarChatAppState();
}

class _OmarChatAppState extends State<OmarChatApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      AppDatabase.instance.store.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ChatListCubit()),
        BlocProvider(create: (_) => GroupCubit()),
        BlocProvider(create: (_) => ProfileCubit()),
        BlocProvider(create: (_) => SettingsCubit()),
      ],
      child: MaterialApp(
        title: 'OMAR Chat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        navigatorObservers: [appRouteObserver],
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final args = routeArgs(settings.arguments);

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(settings: settings, builder: (_) => const SplashScreen());
      case AppRoutes.chatList:
        return MaterialPageRoute(settings: settings, builder: (_) => const ChatListScreen());
      case AppRoutes.chatDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChatDetailScreen(
            chatId: routeInt(args, 'chatId') ?? 0,
            title: routeString(args, 'title') ?? 'Chat',
            otherUserId: routeInt(args, 'otherUserId'),
            isGroupChat: args['isGroup'] == true,
          ),
        );
      case AppRoutes.createGroup:
        return MaterialPageRoute(settings: settings, builder: (_) => const CreateGroupScreen());
      case AppRoutes.search:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SearchScreen(chatId: routeInt(args, 'chatId')),
        );
      case AppRoutes.profile:
        return MaterialPageRoute(settings: settings, builder: (_) => const ProfileScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(settings: settings, builder: (_) => const SettingsScreen());
      case AppRoutes.userDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => UserDetailScreen(userId: routeInt(args, 'userId') ?? 0),
        );
      case AppRoutes.status:
        return MaterialPageRoute(settings: settings, builder: (_) => const StatusScreen());
      case AppRoutes.call:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CallScreen(
            contactName: routeString(args, 'name') ?? 'Contact',
            type: args['type'] == 'video' ? CallType.video : CallType.voice,
            isGroup: args['isGroup'] == true,
          ),
        );
      case AppRoutes.callHistory:
        return MaterialPageRoute(settings: settings, builder: (_) => const CallHistoryScreen());
      default:
        return MaterialPageRoute(settings: settings, builder: (_) => const SplashScreen());
    }
  }
}

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.initialize();
  if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) return;
  try {
    await LocalNotificationService().init().timeout(const Duration(seconds: 2));
  } catch (_) {}
  try {
    await NotificationSoundService().init().timeout(const Duration(seconds: 2));
  } catch (_) {}
}
