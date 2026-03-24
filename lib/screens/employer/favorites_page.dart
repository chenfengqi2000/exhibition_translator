import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/translator_card.dart';
import '../../widgets/state_widgets.dart';
import 'translator_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '我的收藏',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favProvider, _) {
          if (favProvider.isLoading) {
            return const LoadingWidget();
          }
          if (favProvider.error != null) {
            return ErrorRetryWidget(
              message: favProvider.error!,
              onRetry: () => favProvider.loadFavorites(),
            );
          }
          if (favProvider.favorites.isEmpty) {
            return const EmptyWidget(
              message: '暂无收藏的翻译员',
              icon: Icons.favorite_border,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favProvider.favorites.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final translator = favProvider.favorites[index];
              return TranslatorCard(
                translator: translator,
                isFavorited: true,
                onFavoriteToggle: () async {
                  await favProvider.toggleFavorite(translator.id);
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TranslatorDetailPage(translator: translator),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
