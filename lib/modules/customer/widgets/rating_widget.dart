import 'package:flutter/material.dart';

class RatingWidget extends StatefulWidget {
  final double initialRating;
  final Function(double) onRatingChanged;
  final bool isReadOnly;
  
  const RatingWidget({
    super.key,
    required this.initialRating,
    required this.onRatingChanged,
    this.isReadOnly = false,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return GestureDetector(
          onTap: widget.isReadOnly
              ? null
              : () {
                  setState(() {
                    _rating = starValue;
                  });
                  widget.onRatingChanged(_rating);
                },
          child: Icon(
            starValue <= _rating
                ? Icons.star
                : starValue <= _rating + 0.5
                    ? Icons.star_half
                    : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
        );
      }),
    );
  }
} 
