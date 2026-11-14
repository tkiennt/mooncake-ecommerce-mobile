import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

class AntdOtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onComplete;
  final int countdownSeconds;
  final VoidCallback? onResend;

  const AntdOtpInput({
    super.key,
    this.length = 6,
    this.onComplete,
    this.countdownSeconds = 60,
    this.onResend,
  });

  @override
  State<AntdOtpInput> createState() => _AntdOtpInputState();
}

class _AntdOtpInputState extends State<AntdOtpInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late int _timeLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _timeLeft = widget.countdownSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_timeLeft > 0) {
          setState(() {
            _timeLeft--;
          });
        } else {
          _timer?.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String val, int index) {
    if (val.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        final otp = _controllers.map((c) => c.text).join();
        if (otp.length == widget.length) {
          widget.onComplete?.call(otp);
        }
      }
    }
  }

  void _handleResend() {
    if (_timeLeft == 0) {
      setState(() {
        _timeLeft = widget.countdownSeconds;
      });
      _startTimer();
      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      widget.onResend?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            return Container(
              width: 44,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (val) => _onChanged(val, index),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Chưa nhận được mã? ',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            GestureDetector(
              onTap: _timeLeft == 0 ? _handleResend : null,
              child: Text(
                _timeLeft > 0 ? 'Gửi lại sau ${_timeLeft}s' : 'Gửi lại ngay',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _timeLeft > 0 ? AppColors.textMuted : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
