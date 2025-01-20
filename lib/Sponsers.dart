import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:burtonaletrail_app/AppApi.dart';
import 'package:burtonaletrail_app/LoadingScreen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class SpecialOffer {
  final Uint8List imageBytes;
  final String actionUrl;

  SpecialOffer({required this.imageBytes, required this.actionUrl});
}

class SpecialOfferCarousel extends StatefulWidget {
  const SpecialOfferCarousel({Key? key}) : super(key: key);

  @override
  _SpecialOfferCarouselState createState() => _SpecialOfferCarouselState();
}

class _SpecialOfferCarouselState extends State<SpecialOfferCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<SpecialOffer> _offers = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _fetchImagesFromApi();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchImagesFromApi() async {
    var url = apiServerSponsers;

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey("images")) {
          final imagesList = data["images"] as List<dynamic>;
          final List<SpecialOffer> tempOffers = [];

          for (var imageData in imagesList) {
            if (imageData is Map<String, dynamic>) {
              final base64String = imageData["image_base64"] as String?;
              final actionUrl = imageData["action_url"] as String? ?? "";
              if (base64String != null) {
                try {
                  final decodedBytes = base64Decode(base64String);

                  tempOffers.add(SpecialOffer(
                    imageBytes: decodedBytes,
                    actionUrl: actionUrl,
                  ));
                } catch (e) {
                  debugPrint("Error decoding base64 image: $e");
                }
              }
            }
          }

          setState(() {
            _offers = tempOffers;
            _isLoading = false;
          });

          if (_offers.length > 1) {
            _startAutoScroll();
          }
        } else {
          setState(() {
            _errorMessage = "No 'images' field in JSON response.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              "Server error: ${response.statusCode} ${response.reasonPhrase}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Request failed: $e";
        _isLoading = false;
      });
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _offers.isNotEmpty) {
        int nextPage = (_currentPage + 1) % _offers.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPage = nextPage;
        });
      }
    });
  }

  Widget _buildOfferCard(SpecialOffer offer) {
    return InkWell(
      onTap: () {
        if (offer.actionUrl.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Offers are in development. You will soon be navigated to: '
                  '${offer.actionUrl} with your correct sizes to go shopping'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(8),
        constraints: const BoxConstraints(
          maxHeight: 250,
          minHeight: 180,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            offer.imageBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.broken_image, size: 50));
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: LoadingScreen(
        loadingText: "",
      ));
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _offers.length,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildOfferCard(_offers[index]);
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _offers.length,
            (index) {
              final bool isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? Colors.black : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
