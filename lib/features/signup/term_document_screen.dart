import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:pdfrx/pdfrx.dart';

class TermDocumentScreen extends StatefulWidget {
  const TermDocumentScreen({
    super.key,
    required this.title,
    required this.pdfAssetPath,
  });

  final String title;
  final String pdfAssetPath;

  @override
  State<TermDocumentScreen> createState() => _TermDocumentScreenState();
}

class _TermDocumentScreenState extends State<TermDocumentScreen> {
  late Future<bool> _hasPdf;

  @override
  void initState() {
    super.initState();
    _hasPdf = _assetExists(widget.pdfAssetPath);
  }

  @override
  void didUpdateWidget(covariant TermDocumentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pdfAssetPath != widget.pdfAssetPath) {
      _hasPdf = _assetExists(widget.pdfAssetPath);
    }
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('term-document-screen'),
      backgroundColor: AppColors.neutralsSurface,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: widget.title,
              iconRight1: GestureDetector(
                key: const ValueKey('term-document-close'),
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: Icon(
                    Icons.close,
                    size: 24,
                    color: AppColors.foregroundPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<bool>(
                future: _hasPdf,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox.expand();
                  }

                  if (snapshot.data == true) {
                    return ColoredBox(
                      color: AppColors.neutralsSurface,
                      child: PdfViewer.asset(widget.pdfAssetPath),
                    );
                  }

                  return const _BlankDocument(
                    key: ValueKey('term-document-blank'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlankDocument extends StatelessWidget {
  const _BlankDocument({super.key});

  static const double _pageWidth = 328;
  static const double _pageHeight = 522;
  static const double _pageGap = 8;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BlankPage(),
            SizedBox(height: _pageGap),
            _BlankPage(),
          ],
        ),
      ),
    );
  }
}

class _BlankPage extends StatelessWidget {
  const _BlankPage();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '빈 문서',
      child: Container(
        width: _BlankDocument._pageWidth,
        height: _BlankDocument._pageHeight,
        decoration: const BoxDecoration(
          color: AppColors.gray0,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}