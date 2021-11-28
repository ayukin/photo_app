import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_app/photo.dart';
import 'package:photo_app/photo_repository.dart';
import 'package:photo_app/photo_view_screen.dart';
import 'package:photo_app/providers.dart';
import 'package:photo_app/sign_in_screen.dart';

class PhotoListScreen extends StatefulWidget {
  @override
  _PhotoListScreenState createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends State<PhotoListScreen> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();

    _controller = PageController(
      initialPage: context.read(photoListIndexProvider).state,
    );

  }

  @override
  Widget build(BuildContext context) {
    // ログインしているユーザーの情報を取得
    final User user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text("Photo App"),
        actions: [
          // ログアウト用ボタン
          IconButton(
            onPressed: () => _onSignOut(),
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: PageView(
        controller: _controller,
        onPageChanged: (int index) => _onPageChanged(index),
        children: [
          // 「全ての画像」を表示する部分
          Consumer(builder: (context, watch, child) {
            // 「全ての画像」を表示する部分
            final asyncPhotoList = watch(photoListProvider);
            return asyncPhotoList.when(
              data: (List<Photo> photoList) {
                return PhotoGridView(
                  photoList: photoList,
                  onTap: (photo) => _onTapPhoto(photo, photoList),
                  onTapFav: (photo) => _onTapFav(photo),
                );
              },
              loading: () {
                return Center(
                  child: CircularProgressIndicator(),
                );
              },
              error: (e, stackTrace) {
                return Center(
                  child: Text(e.toString()),
                );
              },
            );
          }),

          //「お気に入り登録した画像」を表示する部分
          Consumer(builder: (context, watch, child) {
            // 画像データ一覧を受け取る
            final asyncPhotoList = watch(photoListProvider);
            return asyncPhotoList.when(
              data: (List<Photo> photoList) {
                return PhotoGridView(
                  photoList: photoList,
                  onTap: (photo) => _onTapPhoto(photo, photoList),
                  onTapFav: (photo) => _onTapFav(photo),
                );
              },
              loading: () {
                return Center(
                  child: CircularProgressIndicator(),
                );
              },
              error: (e, stackTrace) {
                return Center(
                  child: Text(e.toString()),
                );
              },
            );
          }),
        ],
      ),

      // 画像追加ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddPhoto(),
        child: Icon(Icons.add),
      ),

      // 画面下部のボタン部分
      bottomNavigationBar: Consumer(
        builder: (context, watch, child) {
          // 現在のページを受け取る
          final photoIndex = watch(photoListIndexProvider).state;

          return BottomNavigationBar(
            onTap: (int index) => _onTapBottomNavigationItem(index),

            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.image),
                label: "フォト",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: "お気に入り",
              ),
            ],
          );
        },
      ),
    );
  }

  void _onPageChanged(int index) {
    // ページの値を更新する
    context.read(photoListIndexProvider).state = index;
  }

  void _onTapBottomNavigationItem(int index) {
    // PageViewで表示するWidgetを切り替える
    _controller.animateToPage(
      index,
      // 表示を切り替えると時にかかる時間（300ミリ秒）
      duration: Duration(milliseconds: 300),
      // アニメーションの動き方
      curve: Curves.easeIn,
    );

    // ページの値を更新する
    context.read(photoListIndexProvider).state = index;
  }

  void _onTapPhoto(Photo photo, List<Photo> photoList) {
    final initialIndex = photoList.indexOf(photo);


    Navigator.of(context).push(
      MaterialPageRoute(
        // ProviderScopeを使いScopedProviderの値を上書きできる
        // ここでは、最初に表示する画像の番号を指定
        builder: (_) => ProviderScope(
          overrides: [
            photoViewInitialIndexProvider.overrideWithValue(initialIndex)
          ],
          child: PhotoViewScreen(),
        ),
      ),
    );
  }

  Future<void> _onSignOut() async {
    // ログアウト処理
    await FirebaseAuth.instance.signOut();

    // ログアウトに成功したらログイン画面に戻す
    // 現在の画面は不要になるのでpushReplacementを使う
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SignInScreen(),
      ),
    );
    print("ログアウト成功");
  }

  Future<void> _onAddPhoto() async {
    // 画像ファイルを選択
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    // 画像ファイルが選択された場合
    if (result != null) {
      // ログイン中のユーザー情報を取得
      final User user = FirebaseAuth.instance.currentUser!;
      final PhotoRepository repository = PhotoRepository(user);
      final File file = File(result.files.single.path!);
      await repository.addPhoto(file);
    }
  }

  Future<void> _onTapFav(Photo photo) async {
    final photoRepository = context.read(photoRepositoryProvider);
    final togledPhoto = photo.togleIsFavorite();
    await photoRepository!.updatePhoto(togledPhoto);
  }

}

class PhotoGridView extends StatelessWidget {

  const PhotoGridView({
    Key? key,
    // 引数から画像のURL一覧を受け取る
    required this.photoList,
    required this.onTap,
    required this.onTapFav,

  }) : super(key: key);

  // コールバックからタップされた画像のURLを受け渡す
  final List<Photo> photoList;
  final void Function(Photo photo) onTap;
  final void Function(Photo photo) onTapFav;

  @override
  Widget build(BuildContext context) {

    // GridViewを使いタイル状にWidgetを表示する
    return GridView.count(
      // １行あたりに表示するWidgetの数
      crossAxisCount: 2,
      // Widget間のスペース（上下）
      mainAxisSpacing: 8,
      // Widget間のスペース（左右）
      crossAxisSpacing: 8,
      // 全体の余白
      padding: const EdgeInsets.all(8),

      // 画像一覧
      children: photoList.map((Photo photo) {
        // Stackを使いWidgetを前後に重ねる
        return Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,

              // Widgetをタップ可能にする
              child: InkWell(
                onTap: () => onTap(photo),
                // URLを指定して画像を表示
                child: Image.network(
                  photo.imageURL,
                  // 画像の表示の仕方を調整できる
                  // 比率は維持しつつ余白がでないようにするのでcoverを指定
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // 画像の上のお気に入りアイコンを重ねて表示
            // Alignment.topRightを指定し右上部分にアイコンを表示
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => onTapFav(photo),
                color: Colors.white,
                icon: Icon(
                  photo.isFavorite == true
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}