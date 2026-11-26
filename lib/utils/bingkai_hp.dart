import 'package:flutter/material.dart';

/// Bingkai iPhone untuk tampilan desktop dan web.
/// Ukuran layar 402 x 874 pt, sama dengan iPhone 17 Pro dan 18 Pro.
/// Ubah konstanta di bawah kalau ingin ukuran lain.
class BingkaiIphone extends StatelessWidget {
  final Widget child;
  const BingkaiIphone({super.key, required this.child});

  static const double lebarLayar = 402;
  static const double tinggiLayar = 874;
  static const double tebalBezel = 12;
  static const double radiusLayar = 52;
  static const double tinggiStatusBar = 54;
  static const double tinggiIndikatorBawah = 24;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    const area = EdgeInsets.fromLTRB(
        0, tinggiStatusBar, 0, tinggiIndikatorBawah);

    return ColoredBox(
      color: const Color(0xFF263238),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              width: lebarLayar + tebalBezel * 2,
              height: tinggiLayar + tebalBezel * 2,
              padding: const EdgeInsets.all(tebalBezel),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B0C),
                borderRadius: BorderRadius.circular(radiusLayar + tebalBezel),
                border: Border.all(color: const Color(0xFF3A3F44), width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black54,
                      blurRadius: 40,
                      offset: Offset(0, 20)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radiusLayar),
                child: MediaQuery(
                  data: mq.copyWith(
                    size: const Size(lebarLayar, tinggiLayar),
                    padding: area,
                    viewPadding: area,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: child),
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: tinggiStatusBar,
                        child: IgnorePointer(child: _StatusBar()),
                      ),
                      const Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Center(
                            child: SizedBox(
                              width: 134,
                              height: 5,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xDD111111),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(3)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Status bar tiruan: jam, Dynamic Island, sinyal, Wi-Fi, baterai.
class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Container(
                width: 120,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 36,
            top: 18,
            child: Text('9:41',
                style: TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          const Positioned(
            right: 30,
            top: 19,
            child: Row(
              children: [
                Icon(Icons.signal_cellular_alt,
                    size: 17, color: Color(0xFF111111)),
                SizedBox(width: 4),
                Icon(Icons.wifi, size: 17, color: Color(0xFF111111)),
                SizedBox(width: 4),
                Icon(Icons.battery_full, size: 19, color: Color(0xFF111111)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
