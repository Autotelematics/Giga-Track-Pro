import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:trackerapp/models/view_report_intial_data.dart';
import 'package:trackerapp/providers/get_device_report_provider.dart';

class GetReportScreen extends StatefulWidget {
  final ViewReportInitialData viewReportInitialData;
  const GetReportScreen(this.viewReportInitialData, {super.key});

  @override
  State<GetReportScreen> createState() => _GetReportScreenState();
}

class _GetReportScreenState extends State<GetReportScreen> {
  late GetReportProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = GetReportProvider()
      ..fetchReports(widget.viewReportInitialData);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report'),
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: ChangeNotifierProvider.value(
          value: _provider,
          child: Consumer<GetReportProvider>(
            builder: (_, p, __) => _buildContent(p),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(GetReportProvider p) {
    switch (p.fetchState) {
      case ReportFetchState.idle:
        return const SizedBox.shrink();

      case ReportFetchState.requesting:
        return _Loading('Requesting report...');

      case ReportFetchState.polling:
        return _PollingView(message: p.pollingMessage);

      case ReportFetchState.downloading:
        return _Loading('Downloading PDF...');

      case ReportFetchState.ready:
        final bytes = p.pdfBytes;
        if (bytes == null || bytes.isEmpty) {
          return _Error('PDF data is empty.', () => p.fetchReports(widget.viewReportInitialData));
        }
        return PdfViewer.data(
          bytes,
          sourceName: 'report.pdf',
          params: const PdfViewerParams(
            margin: 8,
            backgroundColor: Colors.white,
            maxScale: 8,
            minScale: 0.1,
            useAlternativeFitScaleAsMinScale: true,
          ),
        );

      case ReportFetchState.error:
        return _Error(
          p.reportResponse.errorMessage ?? 'Unknown error',
              () => p.fetchReports(widget.viewReportInitialData),
        );
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Loading extends StatelessWidget {
  final String msg;
  const _Loading(this.msg);

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(
          width: 60, height: 60,
          child: CircularProgressIndicator(strokeWidth: 3)),
      const SizedBox(height: 20),
      Text(msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 15)),
    ]),
  );
}

class _Error extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _Error(this.msg, this.onRetry);

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child:
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 72, color: Colors.red),
        const SizedBox(height: 16),
        Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry')),
      ]),
    ),
  );
}

class _PollingView extends StatefulWidget {
  final String message;
  const _PollingView({required this.message});

  @override
  State<_PollingView> createState() => _PollingViewState();
}

class _PollingViewState extends State<_PollingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 80, height: 80,
              child: CircularProgressIndicator(
                  strokeWidth: 4,
                  backgroundColor: Colors.blue.shade100,
                  color: Colors.blue.shade600),
            ),
            const Icon(Icons.description_outlined,
                size: 32, color: Colors.blue),
          ]),
          const SizedBox(height: 28),
          Text(widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87)),
          const SizedBox(height: 8),
          const Text('Do not close this screen.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 28),
          // Pulsing dots
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final t = ((_ctrl.value - i / 3) % 1.0);
                final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2)
                    .clamp(0.2, 1.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                          color: Colors.blue.shade400,
                          shape: BoxShape.circle),
                    ),
                  ),
                );
              }),
            ),
          ),
        ]),
      ),
    );
  }
}