import 'package:flutter/material.dart';
import 'package:photo_app/photo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_app/providers.dart';
import 'package:share/share.dart';

class PhotoViewScreen extends StatefulWidget {

  @override
  _PhotoViewScreenState createState() => _PhotoViewScreenState();

}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();

    _controller = PageController(
      initialPage: context.read(photoViewInitialIndexProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBarの裏までbodyの表示エリアを広げる
      extendBodyBehindAppBar: true,
      // 透明なAppBarを作る
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Consumer(builder: (context, watch, child) {
            final asyncPhotoList = watch(photoListProvider);

            return asyncPhotoList.when(
              data: (photoList) {
                return PageView(
                  controller: _controller,
                  onPageChanged: (int index) => {},
                  // 受け取った画像一覧を表示
                  children: photoList.map((Photo photo) {
                    return Image.network(
                      photo.imageURL,
                      fit: BoxFit.cover,
                    );
                  }).toList(),
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

          // アイコンボタンを画像の手前に重ねる
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              // フッター部分にグラデーションを入れてみる
              decoration: BoxDecoration(
                // 線形グラデーション
                gradient: LinearGradient(
                  // 下方向から上方向に向かってグラデーションさせる
                  begin: FractionalOffset.bottomCenter,
                  end: FractionalOffset.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 共有ボタン
                  IconButton(
                    onPressed: () => _onTapShare(),
                    color: Colors.white,
                    icon: Icon(Icons.share),
                  ),

                  // 削除ボタン
                  IconButton(
                    onPressed: () => _onTapDelete(),
                    color: Colors.white,
                    icon: Icon(Icons.delete),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTapDelete() async {
    final photoRepository = context.read(photoRepositoryProvider);
    final photoList = context.read(photoListProvider).data!.value;
    final photo = photoList[_controller.page!.toInt()];

    if (photoList.length == 1) {
      Navigator.of(context).pop();
    } else if (photoList.last == photo) {
      await _controller.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    await photoRepository!.deletePhoto(photo);
  }

  Future<void> _onTapShare() async {
    final photoList = context.read(photoListProvider).data!.value;
    final photo = photoList[_controller.page!.toInt()];

    // 画像URLを共有
    await Share.share(photo.imageURL);
  }


}