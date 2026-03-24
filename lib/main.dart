import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/employer_service.dart';
import 'services/translator_service.dart';
import 'services/favorite_service.dart';
import 'services/review_service.dart';
import 'services/availability_service.dart';
import 'services/chat_service.dart';
import 'services/notification_service.dart';
import 'services/aftersales_service.dart';
import 'providers/auth_provider.dart';
import 'providers/translator_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/aftersales_provider.dart';
import 'screens/common/login_page.dart';
import 'screens/common/role_selection_page.dart';
import 'screens/employer/employer_main_page.dart';
import 'screens/translator/translator_main_page.dart';
import 'widgets/state_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  final apiClient = ApiClient(storage);
  final authService = AuthService(apiClient);
  final employerService = EmployerService(apiClient);
  final translatorService = TranslatorService(apiClient);
  final favoriteService = FavoriteService(apiClient);
  final reviewService = ReviewService(apiClient);
  final availabilityService = AvailabilityService(apiClient);
  final chatService = ChatService(apiClient);
  final notificationService = NotificationService(apiClient);
  final aftersalesService = AftersalesService(apiClient);

  final authProvider = AuthProvider(
    authService: authService,
    storage: storage,
  );

  // token 失效时自动登出
  apiClient.onUnauthorized = () => authProvider.logout();

  // 启动时检查登录状态
  await authProvider.init();

  runApp(ExhibitionTranslatorApp(
    authProvider: authProvider,
    employerService: employerService,
    translatorService: translatorService,
    favoriteService: favoriteService,
    reviewService: reviewService,
    availabilityService: availabilityService,
    chatService: chatService,
    notificationService: notificationService,
    aftersalesService: aftersalesService,
  ));
}

class ExhibitionTranslatorApp extends StatelessWidget {
  final AuthProvider authProvider;
  final EmployerService employerService;
  final TranslatorService translatorService;
  final FavoriteService favoriteService;
  final ReviewService reviewService;
  final AvailabilityService availabilityService;
  final ChatService chatService;
  final NotificationService notificationService;
  final AftersalesService aftersalesService;

  const ExhibitionTranslatorApp({
    super.key,
    required this.authProvider,
    required this.employerService,
    required this.translatorService,
    required this.favoriteService,
    required this.reviewService,
    required this.availabilityService,
    required this.chatService,
    required this.notificationService,
    required this.aftersalesService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => TranslatorProvider(service: translatorService),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoriteProvider(service: favoriteService),
        ),
        ChangeNotifierProvider(
          create: (_) => AftersalesProvider(aftersalesService),
        ),
        Provider<EmployerService>.value(value: employerService),
        Provider<TranslatorService>.value(value: translatorService),
        Provider<FavoriteService>.value(value: favoriteService),
        Provider<ReviewService>.value(value: reviewService),
        Provider<AvailabilityService>.value(value: availabilityService),
        Provider<ChatService>.value(value: chatService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<AftersalesService>.value(value: aftersalesService),
      ],
      child: MaterialApp(
        title: '展会翻译',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
        locale: const Locale('zh', 'CN'),
        builder: (context, child) {
          return Container(
            color: const Color(0xFF1A1A2E),
            child: Center(
              child: Container(
                width: 393,
                height: 852,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: const Size(393, 852),
                      padding: const EdgeInsets.only(top: 44, bottom: 34),
                    ),
                    child: child!,
                  ),
                ),
              ),
            ),
          );
        },
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(body: LoadingWidget(message: '加载中...'));
            }
            if (!auth.isLoggedIn) {
              return const LoginPage();
            }
            if (auth.role == null) {
              return const RoleSelectionPage();
            }
            // 使用统一枚举: EMPLOYER / TRANSLATOR
            if (auth.role == 'EMPLOYER') {
              return const EmployerMainPage();
            }
            return const TranslatorMainPage();
          },
        ),
      ),
    );
  }
}
