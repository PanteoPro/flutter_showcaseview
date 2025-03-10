/*
 * Copyright (c) 2021 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:math';

import 'package:flutter/material.dart';

import 'enum.dart';
import 'get_position.dart';
import 'measure_size.dart';

const _kDefaultPaddingFromParent = 14.0;

class ToolTipWidget extends StatefulWidget {
  final GetPosition? position;
  final Offset? offset;
  final Size? screenSize;
  final String? title;
  final TextAlign? titleAlignment;
  final String? description;
  final TextAlign? descriptionAlignment;
  final TextStyle? titleTextStyle;
  final TextStyle? descTextStyle;
  final Widget? container;
  final Color? tooltipBackgroundColor;
  final Color? textColor;
  final bool showArrow;
  final double? contentHeight;
  final double? contentWidth;
  final VoidCallback? onTooltipTap;
  final EdgeInsets? tooltipPadding;
  final Duration movingAnimationDuration;
  final bool disableMovingAnimation;
  final bool disableScaleAnimation;
  final BorderRadius? tooltipBorderRadius;
  final Duration scaleAnimationDuration;
  final Curve scaleAnimationCurve;
  final Alignment? scaleAnimationAlignment;
  final bool isTooltipDismissed;
  final TooltipPosition? tooltipPosition;
  final EdgeInsets? titlePadding;
  final EdgeInsets? descriptionPadding;
  final TextDirection? titleTextDirection;
  final TextDirection? descriptionTextDirection;

  const ToolTipWidget({
    Key? key,
    required this.position,
    required this.offset,
    required this.screenSize,
    required this.title,
    required this.titleAlignment,
    required this.description,
    required this.titleTextStyle,
    required this.descTextStyle,
    required this.container,
    required this.tooltipBackgroundColor,
    required this.textColor,
    required this.showArrow,
    required this.contentHeight,
    required this.contentWidth,
    required this.onTooltipTap,
    required this.movingAnimationDuration,
    required this.descriptionAlignment,
    this.tooltipPadding = const EdgeInsets.symmetric(vertical: 8),
    required this.disableMovingAnimation,
    required this.disableScaleAnimation,
    required this.tooltipBorderRadius,
    required this.scaleAnimationDuration,
    required this.scaleAnimationCurve,
    this.scaleAnimationAlignment,
    this.isTooltipDismissed = false,
    this.tooltipPosition,
    this.titlePadding,
    this.descriptionPadding,
    this.titleTextDirection,
    this.descriptionTextDirection,
  }) : super(key: key);

  @override
  State<ToolTipWidget> createState() => _ToolTipWidgetState();
}

class _ToolTipWidgetState extends State<ToolTipWidget>
    with TickerProviderStateMixin {
  Offset? position;

  bool isArrowUp = false;

  late final AnimationController _movingAnimationController;
  late final Animation<double> _movingAnimation;
  late final AnimationController _scaleAnimationController;
  late final Animation<double> _scaleAnimation;

  double tooltipWidth = 0;
  double tooltipScreenEdgePadding = 20;
  double tooltipTextPadding = 15;

  TooltipPosition findPositionForContentVertical(Offset position) {
    var height = 120.0;
    height = widget.contentHeight ?? height;
    final bottomPosition =
        position.dy + ((widget.position?.getHeight() ?? 0) / 2);
    final topPosition = position.dy - ((widget.position?.getHeight() ?? 0) / 2);
    final hasSpaceInTop = topPosition >= height;
    final EdgeInsets viewInsets = EdgeInsets.fromWindowPadding(
        WidgetsBinding.instance.window.viewInsets,
        WidgetsBinding.instance.window.devicePixelRatio);
    final double actualVisibleScreenHeight =
        (widget.screenSize?.height ?? MediaQuery.of(context).size.height) -
            viewInsets.bottom;
    final hasSpaceInBottom =
        (actualVisibleScreenHeight - bottomPosition) >= height;
    return widget.tooltipPosition ??
        (hasSpaceInTop && !hasSpaceInBottom
            ? TooltipPosition.top
            : TooltipPosition.bottom);
  }

  TooltipPosition findPositionForContentHorizontal(Offset position) {
    var width = 120.0;
    width = widget.contentWidth ?? tooltipWidth;
    final leftPosition = position.dx;
    final rightPosition = position.dx + (widget.position?.getWidth() ?? 0);
    final hasSpaceInRight = rightPosition >= width;
    final EdgeInsets viewInsets = EdgeInsets.fromWindowPadding(
        WidgetsBinding.instance.window.viewInsets,
        WidgetsBinding.instance.window.devicePixelRatio);
    final double actualVisibleScreenWidth =
        (widget.screenSize?.width ?? MediaQuery.of(context).size.width) -
            viewInsets.left;
    final hasSpaceInLeft = (actualVisibleScreenWidth - leftPosition) >= width;
    return widget.tooltipPosition ??
        (hasSpaceInRight && !hasSpaceInLeft
            ? TooltipPosition.left
            : TooltipPosition.right);
  }

  void _getTooltipWidth() {
    final titleStyle = widget.titleTextStyle ??
        Theme.of(context)
            .textTheme
            .titleLarge!
            .merge(TextStyle(color: widget.textColor));
    final descriptionStyle = widget.descTextStyle ??
        Theme.of(context)
            .textTheme
            .titleSmall!
            .merge(TextStyle(color: widget.textColor));
    final titleLength = widget.title == null
        ? 0
        : _textSize(widget.title!, titleStyle).width +
            widget.tooltipPadding!.right +
            widget.tooltipPadding!.left +
            (widget.titlePadding?.right ?? 0) +
            (widget.titlePadding?.left ?? 0);
    final descriptionLength = widget.description == null
        ? 0
        : (_textSize(widget.description!, descriptionStyle).width +
            widget.tooltipPadding!.right +
            widget.tooltipPadding!.left +
            (widget.descriptionPadding?.right ?? 0) +
            (widget.descriptionPadding?.left ?? 0));
    var maxTextWidth = max(titleLength, descriptionLength);
    if (maxTextWidth > widget.screenSize!.width - tooltipScreenEdgePadding) {
      tooltipWidth = widget.screenSize!.width - tooltipScreenEdgePadding;
    } else {
      tooltipWidth = maxTextWidth + tooltipTextPadding;
    }
  }

  double? _getLeft() {
    if (widget.position != null) {
      final width =
          widget.container != null ? _customContainerWidth.value : tooltipWidth;
      double leftPositionValue = widget.position!.getXCenter() - (width * 0.5);
      if ((leftPositionValue + width) > MediaQuery.of(context).size.width) {
        return null;
      } else if ((leftPositionValue) < _kDefaultPaddingFromParent) {
        return _kDefaultPaddingFromParent;
      } else {
        return leftPositionValue;
      }
    }
    return null;
  }

  double? _getLeftForHorizontal(double maxWidthText) {
    if (widget.position != null) {
      final width = widget.container != null
          ? _customContainerWidth.value
          : getTooltipWidth(maxWidthText);
      double leftPositionValue = widget.position!.getLeft() - width;
      if ((leftPositionValue + width) > MediaQuery.of(context).size.width) {
        return null;
      } else if ((leftPositionValue) < _kDefaultPaddingFromParent) {
        return _kDefaultPaddingFromParent;
      } else {
        return leftPositionValue;
      }
    }
    return null;
  }

  double? _getRight() {
    if (widget.position != null) {
      final width =
          widget.container != null ? _customContainerWidth.value : tooltipWidth;

      final left = _getLeft();
      if (left == null || (left + width) > MediaQuery.of(context).size.width) {
        final rightPosition = widget.position!.getXCenter() + (width * 0.5);

        return (rightPosition + width) > MediaQuery.of(context).size.width
            ? _kDefaultPaddingFromParent
            : null;
      } else {
        return null;
      }
    }
    return null;
  }

  double? _getRightForHorizontal() {
    if (widget.position != null) {
      final width =
          widget.container != null ? _customContainerWidth.value : tooltipWidth;

      final left = _getLeft();
      if (left == null || (left + width) > MediaQuery.of(context).size.width) {
        final rightPosition = widget.position!.getXCenter() + width;

        return (rightPosition + width) > MediaQuery.of(context).size.width
            ? _kDefaultPaddingFromParent
            : null;
      } else {
        return null;
      }
    }
    return null;
  }

  double _getSpace() {
    var space = widget.position!.getXCenter() - (widget.contentWidth! / 2);
    if (space + widget.contentWidth! > widget.screenSize!.width) {
      space = widget.screenSize!.width - widget.contentWidth! - 8;
    } else if (space < (widget.contentWidth! / 2)) {
      space = 16;
    }
    return space;
  }

  double _getAlignmentX() {
    final calculatedLeft = _getLeft();
    var left = calculatedLeft == null
        ? 0
        : (widget.position!.getXCenter() - calculatedLeft);
    var right = _getLeft() == null
        ? (MediaQuery.of(context).size.width - widget.position!.getXCenter()) -
            (_getRight() ?? 0)
        : 0;
    final containerWidth =
        widget.container != null ? _customContainerWidth.value : tooltipWidth;

    if (left != 0) {
      return (-1 + (2 * (left / containerWidth)));
    } else {
      return (1 - (2 * (right / containerWidth)));
    }
  }

  double _getAlignmentY() {
    var dy = isArrowUp
        ? -1.0
        : (MediaQuery.of(context).size.height / 2) < widget.position!.getTop()
            ? -1.0
            : 1.0;
    return dy;
  }

  final GlobalKey _customContainerKey = GlobalKey();
  final ValueNotifier<double> _customContainerWidth = ValueNotifier<double>(1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.container != null &&
          _customContainerKey.currentContext != null &&
          _customContainerKey.currentContext?.size != null) {
        // TODO: Is it wise to call setState here? All it is doing is setting
        // a value in ValueNotifier which does not require a setState to refresh anyway.
        setState(() {
          _customContainerWidth.value =
              _customContainerKey.currentContext!.size!.width;
        });
      }
    });
    _movingAnimationController = AnimationController(
      duration: widget.movingAnimationDuration,
      vsync: this,
    );
    _movingAnimation = CurvedAnimation(
      parent: _movingAnimationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimationController = AnimationController(
      duration: widget.scaleAnimationDuration,
      vsync: this,
      lowerBound: widget.disableScaleAnimation ? 1 : 0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleAnimationController,
      curve: widget.scaleAnimationCurve,
    );
    if (widget.disableScaleAnimation) {
      movingAnimationListener();
    } else {
      _scaleAnimationController
        ..addStatusListener((scaleAnimationStatus) {
          if (scaleAnimationStatus == AnimationStatus.completed) {
            movingAnimationListener();
          }
        })
        ..forward();
    }
    if (!widget.disableMovingAnimation) {
      _movingAnimationController.forward();
    }
  }

  void movingAnimationListener() {
    _movingAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _movingAnimationController.reverse();
      }
      if (_movingAnimationController.isDismissed) {
        if (!widget.disableMovingAnimation) {
          _movingAnimationController.forward();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    _getTooltipWidth();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _movingAnimationController.dispose();
    _scaleAnimationController.dispose();

    super.dispose();
  }

  double? _getTopPosition() {
    if (widget.position?.getYCenter() == null) return null;
    final titleStyle = widget.titleTextStyle ??
        Theme.of(context)
            .textTheme
            .titleLarge!
            .merge(TextStyle(color: widget.textColor));
    final descriptionStyle = widget.descTextStyle ??
        Theme.of(context)
            .textTheme
            .titleSmall!
            .merge(TextStyle(color: widget.textColor));
    final double descHeight;
    if (widget.description == null) {
      descHeight = 0;
    } else {
      double resultHeight = 0;
      final lines = widget.description!.split('\n');
      for (final line in lines) {
        resultHeight += _textSize(line, descriptionStyle).height;
      }
      resultHeight += widget.tooltipPadding!.top +
          widget.tooltipPadding!.bottom +
          (widget.descriptionPadding?.top ?? 0) +
          (widget.descriptionPadding?.bottom ?? 0);
      descHeight = resultHeight;
    }

    final double titleHeight;
    if (widget.title == null) {
      titleHeight = 0;
    } else {
      double resultHeight = 0;
      final lines = widget.title!.split('\n');
      for (final line in lines) {
        resultHeight += _textSize(line, titleStyle).height;
      }
      resultHeight += widget.tooltipPadding!.top +
          widget.tooltipPadding!.bottom +
          (widget.titlePadding?.top ?? 0) +
          (widget.titlePadding?.bottom ?? 0);
      titleHeight = resultHeight;
    }

    // print('widget.position!.getBottom(); - ${widget.position!.getBottom()}');
    // print('widget.position!.getTop(); - ${widget.position!.getTop()}');
    // print('widget.position!.getYCenter(); - ${widget.position!.getYCenter()}');

    return widget.position!.getYCenter() - titleHeight / 2 - descHeight / 2;
  }

  double getTooltipHeight() {
    final titleStyle = widget.titleTextStyle ??
        Theme.of(context)
            .textTheme
            .titleLarge!
            .merge(TextStyle(color: widget.textColor));
    final descriptionStyle = widget.descTextStyle ??
        Theme.of(context)
            .textTheme
            .titleSmall!
            .merge(TextStyle(color: widget.textColor));
    var descHeight = widget.description == null
        ? 0.0
        : _textSize(widget.description!, descriptionStyle).height +
            widget.tooltipPadding!.top +
            widget.tooltipPadding!.bottom +
            (widget.titlePadding?.top ?? 0) +
            (widget.titlePadding?.bottom ?? 0);
    var titleHeight = widget.title == null
        ? 0.0
        : _textSize(widget.title!, titleStyle).height +
            widget.tooltipPadding!.top +
            widget.tooltipPadding!.bottom +
            (widget.titlePadding?.top ?? 0) +
            (widget.titlePadding?.bottom ?? 0);
    return titleHeight + descHeight;
  }

  double getTooltipWidth([double? maxWidth]) {
    final titleStyle = widget.titleTextStyle ??
        Theme.of(context)
            .textTheme
            .titleLarge!
            .merge(TextStyle(color: widget.textColor));
    final descriptionStyle = widget.descTextStyle ??
        Theme.of(context)
            .textTheme
            .titleSmall!
            .merge(TextStyle(color: widget.textColor));
    final titleLength = widget.title == null
        ? 0.0
        : _textSize(widget.title!, titleStyle, maxWidth).width +
            widget.tooltipPadding!.right +
            widget.tooltipPadding!.left +
            (widget.titlePadding?.right ?? 0) +
            (widget.titlePadding?.left ?? 0);
    final descriptionLength = widget.description == null
        ? 0.0
        : (_textSize(widget.description!, descriptionStyle, maxWidth).width +
            widget.tooltipPadding!.right +
            widget.tooltipPadding!.left +
            (widget.descriptionPadding?.right ?? 0) +
            (widget.descriptionPadding?.left ?? 0));
    tooltipWidth = max(titleLength, descriptionLength);
    return max(titleLength, descriptionLength);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: maybe all this calculation doesn't need to run here. Maybe all or some of it can be moved outside?
    position = widget.offset;
    final contentOrientation = findPositionForContentVertical(position!);
    final contentOrientationHorizontal =
        findPositionForContentHorizontal(position!);

    final Alignment alignmentStack;
    final bool isVerticalArrow;
    final double? left, right, top, arrowLeft, arrowRight, arrowTop;
    double paddingLeftForArrow = 0,
        paddingTopForArrow = 0,
        paddingRightForArrow = 0,
        paddingBottomForArrow = 0;
    final double contentOffsetMultiplier,
        paddingTop,
        paddingBottom,
        arrowWidth,
        arrowHeight;
    if ([TooltipPosition.bottom, TooltipPosition.top]
        .contains(contentOrientation)) {
      isVerticalArrow = true;
      contentOffsetMultiplier =
          contentOrientation == TooltipPosition.bottom ? 1.0 : -1.0;

      isArrowUp = contentOffsetMultiplier == 1.0;

      final contentY = isArrowUp
          ? widget.position!.getBottom() + (contentOffsetMultiplier * 3)
          : widget.position!.getTop() + (contentOffsetMultiplier * 3);

      if (!widget.showArrow) {
        paddingTop = 10;
        paddingBottom = 10;
      } else {
        paddingTop = isArrowUp ? 22.0 : 0.0;
        paddingBottom = isArrowUp ? 0.0 : 27.0;
      }

      arrowWidth = 18.0;
      arrowHeight = 9.0;

      arrowLeft = _getArrowLeft(arrowWidth);
      arrowRight = _getArrowRight(arrowWidth);
      arrowTop = null;

      if (!widget.disableScaleAnimation && widget.isTooltipDismissed) {
        _scaleAnimationController.reverse();
      }

      left = _getLeft();
      right = _getRight();
      top = contentY;

      alignmentStack = isArrowUp
          ? Alignment.topLeft
          : _getLeft() == null
              ? Alignment.bottomRight
              : Alignment.bottomLeft;
      paddingTopForArrow = isArrowUp ? arrowHeight - 1 : 0;
      paddingBottomForArrow = isArrowUp ? 0 : arrowHeight - 1;
    } else {
      isVerticalArrow = false;
      arrowWidth = 9.0;
      arrowHeight = 18.0;
      contentOffsetMultiplier = 0;
      final paddingRight = isArrowUp ? 0 : 27.0;
      final paddingLeft = isArrowUp ? 22.0 : 0;
      left = _getLeftForHorizontal(
              widget.position!.getLeft() - paddingRight - paddingLeft - 30)! -
          paddingRight -
          paddingLeft;
      right = MediaQuery.of(context).size.width - left - tooltipWidth;
      paddingTop = 0;
      paddingBottom = 0;
      arrowLeft = tooltipWidth - arrowWidth + 1;
      arrowRight = 0;
      arrowTop = null;

      top = _getTopPosition() != null ? _getTopPosition()! : 0;
      alignmentStack = isArrowUp ? Alignment.centerRight : Alignment.centerLeft;
      paddingLeftForArrow = isArrowUp ? arrowWidth - 1 : 0;
      paddingRightForArrow = isArrowUp ? 0 : arrowWidth - 1;
    }

    // print('left - $left');
    // print('right - $right');

    final num contentFractionalOffset =
        contentOffsetMultiplier.clamp(-1.0, 0.0);

    if (widget.container == null) {
      return Positioned(
        top: top,
        left: left,
        right: isVerticalArrow
            ? right
            : right != null
                ? right - arrowWidth
                : null,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: widget.scaleAnimationAlignment ??
              Alignment(
                _getAlignmentX(),
                _getAlignmentY(),
              ),
          child: FractionalTranslation(
            translation: Offset(0.0, contentFractionalOffset as double),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.0, contentFractionalOffset / 10),
                end: const Offset(0.0, 0.100),
              ).animate(_movingAnimation),
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: widget.showArrow
                      ? EdgeInsets.only(
                          top: paddingTop != 0
                              ? paddingTop - (isArrowUp ? arrowHeight : 0)
                              : 0,
                          bottom: paddingBottom != 0
                              ? paddingBottom - (isArrowUp ? 0 : arrowHeight)
                              : 0,
                        )
                      : null,
                  child: Stack(
                    alignment: alignmentStack,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: paddingTopForArrow,
                          bottom: paddingBottomForArrow,
                          left: paddingLeftForArrow,
                          right: paddingRightForArrow,
                        ),
                        child: ClipRRect(
                          borderRadius: widget.tooltipBorderRadius ??
                              BorderRadius.circular(8.0),
                          child: GestureDetector(
                            onTap: widget.onTooltipTap,
                            child: Container(
                              width: tooltipWidth,
                              padding: widget.tooltipPadding,
                              color: widget.tooltipBackgroundColor,
                              child: Column(
                                crossAxisAlignment: widget.title != null
                                    ? CrossAxisAlignment.start
                                    : CrossAxisAlignment.center,
                                children: <Widget>[
                                  if (widget.title != null)
                                    Padding(
                                      padding: widget.titlePadding ??
                                          EdgeInsets.zero,
                                      child: Text(
                                        widget.title!,
                                        textAlign: widget.titleAlignment,
                                        textDirection:
                                            widget.titleTextDirection,
                                        style: widget.titleTextStyle ??
                                            Theme.of(context)
                                                .textTheme
                                                .titleLarge!
                                                .merge(
                                                  TextStyle(
                                                    color: widget.textColor,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  Padding(
                                    padding: widget.descriptionPadding ??
                                        EdgeInsets.zero,
                                    child: Text(
                                      widget.description!,
                                      textAlign: widget.descriptionAlignment,
                                      textDirection:
                                          widget.descriptionTextDirection,
                                      style: widget.descTextStyle ??
                                          Theme.of(context)
                                              .textTheme
                                              .titleSmall!
                                              .merge(
                                                TextStyle(
                                                  color: widget.textColor,
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
                      if (widget.showArrow)
                        Positioned(
                          top: arrowTop,
                          left: arrowLeft,
                          right: arrowRight,
                          child: CustomPaint(
                            painter: _Arrow(
                              strokeColor: widget.tooltipBackgroundColor!,
                              strokeWidth: 10,
                              paintingStyle: PaintingStyle.fill,
                              isUpArrow: isArrowUp,
                              isVerticalArrow: isVerticalArrow,
                            ),
                            child: SizedBox(
                              height: arrowHeight,
                              width: arrowWidth,
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
      );
    }
    return Stack(
      children: <Widget>[
        Positioned(
          left: _getSpace(),
          top: top - 10,
          child: FractionalTranslation(
            translation: Offset(0.0, contentFractionalOffset as double),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0.0, contentFractionalOffset / 10),
                end: !widget.showArrow && !isArrowUp
                    ? const Offset(0.0, 0.0)
                    : const Offset(0.0, 0.100),
              ).animate(_movingAnimation),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: widget.onTooltipTap,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: paddingTop,
                    ),
                    color: Colors.transparent,
                    child: Center(
                      child: MeasureSize(
                        onSizeChange: onSizeChange,
                        child: widget.container,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void onSizeChange(Size? size) {
    var tempPos = position;
    tempPos = Offset(position!.dx, position!.dy + size!.height);
    setState(() => position = tempPos);
  }

  Size _textSize(String text, TextStyle style, [double? maxWidth]) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth ?? double.infinity);
    return textPainter.size;
  }

  double? _getArrowLeft(double arrowWidth) {
    final left = _getLeft();
    if (left == null) return null;
    return (widget.position!.getXCenter() - (arrowWidth / 2) - left);
  }

  double? _getArrowRight(double arrowWidth) {
    if (_getLeft() != null) return null;
    return (MediaQuery.of(context).size.width - widget.position!.getXCenter()) -
        (_getRight() ?? 0) -
        (arrowWidth / 2);
  }
}

class _Arrow extends CustomPainter {
  final Color strokeColor;
  final PaintingStyle paintingStyle;
  final double strokeWidth;
  final bool isUpArrow;
  final bool isVerticalArrow;
  final Paint _paint;

  _Arrow({
    this.strokeColor = Colors.black,
    this.strokeWidth = 3,
    this.paintingStyle = PaintingStyle.stroke,
    this.isUpArrow = true,
    this.isVerticalArrow = true,
  }) : _paint = Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = paintingStyle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(getTrianglePath(size.width, size.height), _paint..color);
  }

  Path getTrianglePath(double x, double y) {
    if (!isVerticalArrow) {
      if (isUpArrow) {
        return Path()
          ..moveTo(0, 0)
          ..lineTo(x, y / 2)
          ..lineTo(0, y)
          ..lineTo(0, 0);
      } else {
        return Path()
          ..moveTo(0, 0)
          ..lineTo(x, y / 2)
          ..lineTo(0, y)
          ..lineTo(0, 0);
      }
    }
    if (isUpArrow) {
      return Path()
        ..moveTo(0, y)
        ..lineTo(x / 2, 0)
        ..lineTo(x, y)
        ..lineTo(0, y);
    }
    return Path()
      ..moveTo(0, 0)
      ..lineTo(x, 0)
      ..lineTo(x / 2, y)
      ..lineTo(0, 0);
  }

  @override
  bool shouldRepaint(covariant _Arrow oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.paintingStyle != paintingStyle ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
