import 'package:emoroid_digest_app/utils/local_file.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/visual_summary.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as ImageConvert;

class VisualSummaryThumbnail extends StatelessWidget with LocalFileSystem {
  const VisualSummaryThumbnail({
    Key? key,
    required this.visualSummary,
  }) : super(key: key);

  final VisualSummary visualSummary;

  Future<bool> downloadAndCompressThumbnail() async {
    String localThumbnailPath = getFilePath(visualSummary.linkVisualSummaryThumbnailStorage!);
    var mimeType = ".${localThumbnailPath.split('.').last}";
    localThumbnailPath = localThumbnailPath.replaceAll(".png", ".jpg");
    if (mimeType == ".pdf") {
      return false;
    }
    if (await File(localThumbnailPath).exists()) {
      return true;
    }
    var tempPath = await getTempFilePath(visualSummary.linkVisualSummaryThumbnailStorage!);
    List<String> createDir = [];
    createDir.add((await getFilePath(visualSummary.linkVisualSummaryThumbnailStorage!.split("/")[0])));
    createDir.add((await getTempFilePath(visualSummary.linkVisualSummaryThumbnailStorage!.split("/")[0])));
    for (var i = 0; i < createDir.length; i++) {
      bool hasExisted = await Directory(createDir[i]).exists();
      if (!hasExisted) {
        await Directory(createDir[i]).create();
      }
    }
    try {
      await Dio().download(visualSummary.linkVisualSummaryThumbnailSource!, tempPath);
    } catch (error) {
      print("Error downloaded visual summary thumbnail ${visualSummary.title}.");
      return false;
    }
    if (mimeType == ".png") {
      final imageToJPG = ImageConvert.decodeImage(File(tempPath).readAsBytesSync())!;
      File(tempPath).writeAsBytesSync(ImageConvert.encodeJpg(imageToJPG));
    }
    try {
      var result = await FlutterImageCompress.compressAndGetFile(File(tempPath).absolute.path, localThumbnailPath,
          quality: 1, format: CompressFormat.jpeg);
      File(tempPath).delete();
      return true;
    } catch (error) {
      print("Error compressing visual summary thumbnail ${visualSummary.title}.");
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final localThumbnail =
        File(getFilePath(visualSummary.linkVisualSummaryThumbnailStorage!).replaceAll(".png", ".jpg"));
    return FutureBuilder(
        future: downloadAndCompressThumbnail(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          try {
            if (visualSummary.mimeTypeVisualSummaryThumbnail == "application/pdf") {
              if (snapshot.data! == false) {
                return SizedBox(
                    height: 240.0,
                    child: SfPdfViewer.network(visualSummary.linkVisualSummaryThumbnailSource!,
                        enableDoubleTapZooming: false));
              }
              return SizedBox(height: 240.0, child: SfPdfViewer.file(localThumbnail, enableDoubleTapZooming: false));
            } else {
              if (snapshot.data! == false) {
                return Image.network(visualSummary.linkVisualSummaryThumbnailSource!,
                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => child,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    });
              }
              return Image.file(localThumbnail);
            }
          } catch (e) {
            print("Error loading thumbnail: " + e.toString());
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }
}
