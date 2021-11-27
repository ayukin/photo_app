import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:photo_app/photo_view_screen.dart';
import 'package:photo_app/sign_in_screen.dart';

class PhotoListScreen extends StatefulWidget {
  @override
  _PhotoListScreenState createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends State<PhotoListScreen> {

  late int _currentIndex;
  late PageController _controller;

  @override
  void initState() {
    super.initState();

    // PageViewで表示されているWidgetの番号を持っておく
    _currentIndex = 0;

    // PageViewの表示を切り替えるのに使う
    _controller = PageController(initialPage: _currentIndex);

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
      body: StreamBuilder<QuerySnapshot>(
        // CloudFirestoreからデータを取得
        stream: FirebaseFirestore.instance
            .collection("users/${user.uid}/photos")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // CloudFirestoreからデータを取得中の場合
          if (snapshot.hasData == false) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          // CloudFirestoreからデータを取得完了した場合
          final QuerySnapshot<Object?>? query = snapshot.data;
          // 画像のURL一覧を作成
          final List<String> imageList = query!.docs
              .map((doc) => doc.get("imageURL") as String)
              .toList();

          return PageView(
            controller: _controller,
            // 表示が切り替わった時
            onPageChanged: (int index) => _onPageChanged(index),

            children: [
              // 「全ての画像」を表示する部分
              PhotoGridView(
                // Cloud Firestoreから取得した画像のURL一覧を渡す
                imageList: imageList,
                // コールバックを設定しタップした画像のURLを受け取る
                onTap: (imageURL) => _onTapPhoto(imageURL, imageList),
              ),

              // 「お気に入り登録した画像」を表示する部分
              PhotoGridView(
                // お気に入り登録した画像は、後ほど実装
                imageList: [],
                // コールバックを設定しタップした画像のURLを受け取る
                onTap: (imageURL) => _onTapPhoto(imageURL, imageList),
              ),

            ],
          );
        },
      ),

      // 画像追加ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddPhoto(),
        child: Icon(Icons.add),
      ),

      // 画面下部のボタン部分
      bottomNavigationBar: BottomNavigationBar(
        // BottomNavigationBarItemがタップされたときの処理
        // ０：フォト
        // １：お気に入り
        onTap: (int index) => _onTapBottomNavigationItem(index),

        // 現在表示されているBottomNavigationBarItemの番号
        // ０：フォト
        // １：お気に入り
        currentIndex: _currentIndex,

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
      ),
    );
  }

  void _onPageChanged(int index) {
    // PageViewで表示されているWidgetの番号を更新
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTapBottomNavigationItem(int index) {
    // PageViewで表示するWidgetを切り替える
    _controller.animateToPage(

      // 表示するWidgetの番号
      // ０：フォト
      // １：お気に入り
      index,

      // 表示を切り替えると時にかかる時間（300ミリ秒）
      duration: Duration(milliseconds: 300),

      // アニメーションの動き方
      curve: Curves.easeIn,
    );

    // PageViewで表示されているWidgetの番号を更新
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTapPhoto(String imageURL, List<String> imageList) {
    // 最初に表示する画像のURLを指定して、画像詳細画面に切り替える
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewScreen(
          imageURL: imageURL,
          imageList: imageList,
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

      // フォルダとファイル名を指定し画像ファイルをアップロード
      final int timestamp = DateTime.now().microsecondsSinceEpoch;
      final File file = File(result.files.single.path!);
      final String name = file.path.split("/").last;
      final String path = "${timestamp}_$name";
      final TaskSnapshot task = await FirebaseStorage.instance
          .ref()
          .child("users/${user.uid}/photos") // フォルダ名
          .child(path) // ファイル名
          .putFile(file); // 画像ファイル
      print("画像の保存に成功");

      // アップロードした画像のURLを取得
      final String imageURL = await task.ref.getDownloadURL();
      // アップロードした画像の保存先を取得
      final String imagePath = task.ref.fullPath;
      // データ
      final data = {
        "imageURL": imageURL,
        "imagePath": imagePath,
        "isFavorite": false, // お気に入り登録
        "createdAt": Timestamp.now(), // 現在時刻
      };

      // データをCloudFirestoreに保存
      await FirebaseFirestore.instance
          .collection("users/${user.uid}/photos") // コレクション
          .doc() // ドキュメント（何も指定しない場合は自動的にIDが決まる）
          .set(data); // データ
    }
  }

}

class PhotoGridView extends StatelessWidget {

  const PhotoGridView({
    Key? key,
    // 引数から画像のURL一覧を受け取る
    required this.imageList,
    required this.onTap,
  }) : super(key: key);

  // コールバックからタップされた画像のURLを受け渡す
  final List<String> imageList;
  final void Function(String imageURL) onTap;


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
      children: imageList.map((String imageURL) {
        // Stackを使いWidgetを前後に重ねる
        return Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,

              // Widgetをタップ可能にする
              child: InkWell(
                onTap: () => {},
                // URLを指定して画像を表示
                child: Image.network(
                  imageURL,
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
                onPressed: () => {},
                color: Colors.white,
                icon: Icon(Icons.favorite_border),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}