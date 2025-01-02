import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import for loading spinner

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flood Detection App',

      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    WeatherPage(),
    DetectionPage(),
    ForecastPage(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: const Color.fromARGB(255, 224, 30, 159),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny), // Changed to a weather icon
            label: 'Current Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Detection',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Forecast',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flood Detection App'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueGrey[800],
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.blueGrey[100]!,
              Colors.green[100]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Flood Detection App',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              _buildGradientButton(
                context,
                'Start Detection',
                Icons.search,
                DetectionPage(),
                Colors.blueAccent,
                Colors.lightBlueAccent,
              ),
              SizedBox(height: 20),
              _buildGradientButton(
                context,
                'Flood Precautions',
                Icons.health_and_safety,
                PrecautionPage(),
                Colors.orange[600]!,
                Colors.orangeAccent,
              ),
              SizedBox(height: 20),
              _buildGradientButton(
                context,
                'Flood Prevention',
                Icons.shield,
                PreventionPage(),
                Colors.redAccent,
                Colors.red[400]!,
              ),
              SizedBox(height: 20),
              _buildGradientButton(
                context,
                'Current Weather',
                Icons.cloud,
                WeatherPage(),
                Colors.green[700]!,
                Colors.greenAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton(
    BuildContext context,
    String label,
    IconData icon,
    Widget targetPage,
    Color startColor,
    Color endColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetPage),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startColor, endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 5),
                blurRadius: 10,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  bool _isLoading = false;

  final String weatherApiKey = 'a23105f5f07ed8894973f46e3bbdce39'; // Replace with your API key
  final String weatherApiUrl = 'https://api.openweathermap.org/data/2.5/';

  Future<void> getWeather() async {
    String pincode = _pincodeController.text;

    if (_villageController.text.isEmpty || pincode.isEmpty) {
      _showError("Please enter both village name and pincode.");
      return;
    }

    if (!_isValidPincode(pincode)) {
      _showError("Please enter a valid 6-digit pincode.");
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showError("No internet connection. Please check your network settings.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Location> locations = await locationFromAddress(pincode);
      double latitude = locations[0].latitude;
      double longitude = locations[0].longitude;

      final currentWeatherUrl =
          '${weatherApiUrl}weather?lat=$latitude&lon=$longitude&appid=$weatherApiKey&units=metric';
      final currentWeatherResponse = await http.get(Uri.parse(currentWeatherUrl));

      if (currentWeatherResponse.statusCode == 200) {
        var weatherData = jsonDecode(currentWeatherResponse.body);
        double temperature = weatherData['main']['temp'].toDouble();
        double humidity = weatherData['main']['humidity'].toDouble();
        double windSpeed = weatherData['wind']['speed'].toDouble();
        String weatherDescription = weatherData['weather'][0]['description'];
        String icon = weatherData['weather'][0]['icon'];

        // Calculate sunset condition
        int sunsetTime = weatherData['sys']['sunset'];
        DateTime sunset = DateTime.fromMillisecondsSinceEpoch(sunsetTime * 1000);
        DateTime now = DateTime.now();

        // Check if it's day or night, based on sunset
        bool isDayTime = now.isBefore(sunset);

        String backgroundImage;
        // Determine background image based on weather conditions and time of day
        if (isDayTime) {
          backgroundImage = _getBackgroundImageForDay(icon);
        } else {
          backgroundImage = _getBackgroundImageForNight(icon);
        }

        // Navigate to the result page with updated background
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeatherResultPage(
              weatherMessage:
                  "Temperature: ${temperature}°C\nHumidity: ${humidity}%\nWind Speed: ${windSpeed} m/s\nCondition: $weatherDescription",
              backgroundImage: backgroundImage,
            ),
          ),
        );
      } else {
        _showError("Failed to retrieve weather information.");
      }
    } catch (e) {
      _showError("network issue.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Determine the background image based on weather conditions during the day
  String _getBackgroundImageForDay(String icon) {
    if (icon.contains('d')) {
      return 'assets/day.jpg'; // Daytime, clear or cloudy weather
    } else if (icon == '09d' || icon == '10d') {
      return 'assets/rainfall.jpg'; // Rainy weather during the day
    } else if (icon == '13d') {
      return 'assets/snow.jpg'; // Snowy weather during the day
    } else {
      return 'assets/day.jpg'; // Default to day image
    }
  }

  // Determine the background image based on weather conditions at night
  String _getBackgroundImageForNight(String icon) {
    if (icon.contains('n')) {
      return 'assets/night.jpg'; // Nighttime
    } else if (icon == '09n' || icon == '10n') {
      return 'assets/rainfall.jpg'; // Rainy weather at night
    } else if (icon == '13n') {
      return 'assets/snow.jpg'; // Snowy weather at night
    } else {
      return 'assets/night.jpg'; // Default to night image
    }
  }

  bool _isValidPincode(String pincode) {
    final pincodeRegex = RegExp(r'^\d{6}$');
    return pincodeRegex.hasMatch(pincode);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Current Weather'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueGrey[800],
        elevation: 5,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,           // White
              Colors.blueGrey[100]!,  // Light blue-grey for professionalism
              Colors.green[100]!,     // Light green for calmness
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center( // Center the content vertically
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center the input fields
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Get Weather Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 24, 23, 23),
                  ),
                ),
                SizedBox(height: 20),
                // Village name input field with an icon
                TextField(
                  controller: _villageController,
                  decoration: InputDecoration(
                    labelText: 'Village Name',
                    labelStyle: TextStyle(color: const Color.fromARGB(255, 10, 10, 10)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2).withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.location_on, color: const Color.fromARGB(255, 20, 19, 19)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  style: TextStyle(color: const Color.fromARGB(255, 13, 13, 13)),
                ),
                SizedBox(height: 15),
                // Pincode input field with an icon
                TextField(
                  controller: _pincodeController,
                  decoration: InputDecoration(
                    labelText: 'Pincode',
                    labelStyle: TextStyle(color: const Color.fromARGB(255, 14, 14, 14)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.pin, color: const Color.fromARGB(255, 14, 13, 13)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: const Color.fromARGB(255, 20, 20, 20)),
                ),
                SizedBox(height: 20),
                // Button with a loading indicator
                ElevatedButton(
                  onPressed: getWeather,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Get Weather',
                          style: TextStyle(fontSize: 18),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WeatherResultPage extends StatelessWidget {
  final String weatherMessage;
  final String backgroundImage;

  WeatherResultPage({
    required this.weatherMessage,
    required this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content with App Bar-style Back Navigation
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar-like Back Button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.pop(context); // Navigate back to input page
                    },
                  ),
                ),
                // Weather Information Centered in the Screen
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Weather Message
                          Text(
                            weatherMessage,
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2),
                                  blurRadius: 3,
                                  color: Colors.black.withOpacity(0.6),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class DetectionPage extends StatefulWidget {
  @override
  _DetectionPageState createState() => _DetectionPageState();
}
class _DetectionPageState extends State<DetectionPage> {
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  String _weatherMessage = '';
  String _floodRiskMessage = '';
  bool _isLoading = false;

  final String weatherApiKey = 'a23105f5f07ed8894973f46e3bbdce39'; // Replace with your OpenWeatherMap API key
  final String weatherApiUrl = 'https://api.openweathermap.org/data/2.5/';

  Future<void> checkFloodRisk() async {
    String villageName = _villageController.text;
    String pincode = _pincodeController.text;

    // Validate inputs
    if (villageName.isEmpty || pincode.isEmpty) {
      setState(() {
        _weatherMessage = "Please enter both village name and pincode.";
        _floodRiskMessage = '';
      });
      return;
    }

    if (!_isValidPincode(pincode)) {
      setState(() {
        _weatherMessage = "Pincode does not match. Please enter a valid 6-digit pincode.";
        _floodRiskMessage = '';
      });
      return;
    }

    // Check internet connectivity
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _weatherMessage = "No internet connection. Please check your network settings.";
        _floodRiskMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _weatherMessage = 'Fetching weather data...';
      _floodRiskMessage = '';
    });

    try {
      // Step 1: Get Coordinates from Pincode
      List<Location> locations = await locationFromAddress(pincode);
      double latitude = locations[0].latitude;
      double longitude = locations[0].longitude;

      // Step 2: Get Current Weather Data
      final currentWeatherUrl =
          '${weatherApiUrl}weather?lat=$latitude&lon=$longitude&appid=$weatherApiKey&units=metric';
      final currentWeatherResponse = await http.get(Uri.parse(currentWeatherUrl));

      double currentRainfall = 0.0;

      if (currentWeatherResponse.statusCode == 200) {
        var weatherData = jsonDecode(currentWeatherResponse.body);
        double temperature = weatherData['main']['temp'].toDouble();
        double humidity = weatherData['main']['humidity'].toDouble();
        String weatherDescription = weatherData['weather'][0]['description'];

        // Check if rainfall is present in current data
        if (weatherData['rain'] != null && weatherData['rain']['1h'] != null) {
          currentRainfall = weatherData['rain']['1h'].toDouble();
        }

        // Step 3: Get Historical Rainfall Data for the Last 24 Hours
        final historicalWeatherUrl =
            '${weatherApiUrl}onecall/timemachine?lat=$latitude&lon=$longitude&dt=${(DateTime.now().millisecondsSinceEpoch / 1000).toInt()}&appid=$weatherApiKey';
        final historicalWeatherResponse = await http.get(Uri.parse(historicalWeatherUrl));

        double historicalRainfall = 0.0;

        if (historicalWeatherResponse.statusCode == 200) {
          var historicalData = jsonDecode(historicalWeatherResponse.body);
          historicalRainfall = 0.0;

          // Summing up the rainfall over the last 24 hours
          for (var hour in historicalData['hourly']) {
            if (hour['rain'] != null && hour['rain']['1h'] != null) {
              historicalRainfall += hour['rain']['1h'].toDouble();
            }
          }

          _weatherMessage += "\nTotal Rainfall in Last 24 Hours: ${historicalRainfall} mm";
        }

        _weatherMessage =
            "Current temperature: ${temperature}°C\nHumidity: ${humidity}%\nCondition: $weatherDescription\nCurrent Rainfall (last hour): ${currentRainfall} mm\nTotal Rainfall in Last 24 Hours: ${historicalRainfall} mm";

        // Step 4: Assess Flood Risk Based on Data
        _floodRiskMessage = _assessFloodRisk(temperature, humidity, historicalRainfall);
      } else {
        _weatherMessage = "Failed to retrieve current weather information.";
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _weatherMessage = "An error occurred: network issue";
        _floodRiskMessage = "Could not check flood risk.";
        _isLoading = false;
      });
    }
  }

  bool _isValidPincode(String pincode) {
    final pincodeRegex = RegExp(r'^\d{6}$');
    return pincodeRegex.hasMatch(pincode);
  }

String _assessFloodRisk(double temperature, double humidity, double rainfall) {
  // High flood risk: Heavy rainfall, high humidity, and extreme temperatures
  if (rainfall > 50 && humidity > 85) {
    return "High flood risk due to heavy rainfall and high humidity.";
  }
  
  // Moderate flood risk: Moderate rainfall or high humidity, or high temperature
  else if ((rainfall > 20 && rainfall <= 50) || humidity > 80 || temperature > 30) {
    return "Moderate flood risk due to moderate rainfall, high humidity, or high temperature.";
  }
  
  // Low flood risk: Light rainfall or elevated humidity, or high but not extreme temperature
  else if ((rainfall > 0 && rainfall <= 20) || humidity > 75 || temperature > 25) {
    return "Possible flood risk due to light rainfall, elevated humidity, or moderate temperature.";
  }

  // No flood risk: No significant rainfall, low humidity, and normal temperatures
  else {
    return "No flood risk based on current conditions.";
  }
}
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flood Detection'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueGrey[800], // Subtle, professional color
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.blueGrey[100]!,
              Colors.green[100]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Village Name TextField with icon
            TextField(
              controller: _villageController,
              decoration: InputDecoration(
                labelText: 'Village Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city, color: Colors.green),
              ),
            ),
            SizedBox(height: 10),
            // Pincode TextField with icon
            TextField(
              controller: _pincodeController,
              decoration: InputDecoration(
                labelText: 'Pincode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code, color: Colors.green),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            // Check Flood Risk Button
            ElevatedButton(
              onPressed: checkFloodRisk,
              child: _isLoading
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : Text('Check Flood Risk'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 20),
            // Weather Message with rounded container and shadow
            if (_weatherMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  _weatherMessage,
                  style: TextStyle(fontSize: 18, color: Colors.blue[800]),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 20),
            // Flood Risk Message with rounded container and shadow
            if (_floodRiskMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 205, 249, 255),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 70, 4, 146)
                          .withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  _floodRiskMessage,
                  style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 241, 32, 137)),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class ForecastPage extends StatefulWidget {
  @override
  _ForecastPageState createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  bool _loading = true;
  List<dynamic> _forecastData = [];

  // Function to get the weather forecast
  Future<void> _getWeatherForecast() async {
    const String apiKey = 'a23105f5f07ed8894973f46e3bbdce39'; // Replace with your OpenWeatherMap API key
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?lat=20.5937&lon=78.9629&units=metric&cnt=5&appid=$apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _forecastData = data['list']; // Forecast data
          _loading = false;
        });
      } else {
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      print('Provide network connection');
    }
  }

  @override
  void initState() {
    super.initState();
    _getWeatherForecast();
  }

  // Function to format the date
  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute}';
  }

  // Function to return an icon based on weather condition
  Widget _getWeatherIcon(String weather) {
    switch (weather.toLowerCase()) {
      case 'clear sky':
        return Icon(Icons.wb_sunny, size: 50, color: Colors.orange);
      case 'clouds':
        return Icon(Icons.cloud, size: 50, color: Colors.grey);
      case 'rain':
        return Icon(Icons.grain, size: 50, color: Colors.blue);
      case 'snow':
        return Icon(Icons.ac_unit, size: 50, color: Colors.blueAccent);
      default:
        return Icon(Icons.wb_cloudy, size: 50, color: Colors.blue);
    }
  }
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Forecast'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueGrey[800],
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.blueGrey[100]!,
              Colors.green[100]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _loading
            ? Center(
                child: SpinKitFadingCircle(
                  color: Colors.white,
                  size: 50.0,
                ),
              )
            : ListView.builder(
                itemCount: _forecastData.length,
                itemBuilder: (context, index) {
                  final forecast = _forecastData[index];
                  final weather = forecast['weather'][0]['description'];
                  final temp = forecast['main']['temp'];
                  final humidity = forecast['main']['humidity'];
                  final windSpeed = forecast['wind']['speed'];
                  final rain = forecast['rain'] != null
                      ? forecast['rain']['3h']
                      : 0;

                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _getWeatherIcon(weather), // Using the custom icon function
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDate(forecast['dt']),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Weather: $weather',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Temp: ${temp.toStringAsFixed(1)}°C',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Humidity: $humidity%',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Wind Speed: $windSpeed m/s',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Rain: $rain mm',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class PrecautionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flood Precautions'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.lightBlueAccent ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Precautions During Flood:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 234, 20, 156),
                shadows: [Shadow(color: Colors.black.withOpacity(0.5), offset: Offset(2, 2), blurRadius: 3)],
              ),
            ),
            SizedBox(height: 10),
            precautionCard(
              'Move to higher ground immediately.',
              FontAwesomeIcons.mountain,
              Colors.green,
            ),
            precautionCard(
              'Avoid walking or driving through floodwaters.',
              FontAwesomeIcons.bolt,
              Colors.red,
            ),
            precautionCard(
              'Keep emergency supplies ready.',
              FontAwesomeIcons.firstAid,
              Colors.blue,
            ),
            precautionCard(
              'Stay informed with weather updates.',
              FontAwesomeIcons.cloudSunRain,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget precautionCard(String text, IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 30, color: color),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// 4. Prevention Page

class PreventionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flood Prevention'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flood Prevention Tips:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color.fromRGBO(235, 15, 140, 1),
                shadows: [Shadow(color: Colors.black.withOpacity(0.5), offset: Offset(2, 2), blurRadius: 3)],
              ),
            ),
            SizedBox(height: 10),
            preventionCard(
              'Clean drains and canals regularly.',
              FontAwesomeIcons.water,
              Colors.green,
            ),
            preventionCard(
              'Build levees and flood walls.',
              FontAwesomeIcons.building,
              Colors.blue,
            ),
            preventionCard(
              'Install flood warning systems.',
              FontAwesomeIcons.bell,
              Colors.yellow,
            ),
            preventionCard(
              'Avoid construction on floodplains.',
              FontAwesomeIcons.home,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget preventionCard(String text, IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 30, color: color),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
