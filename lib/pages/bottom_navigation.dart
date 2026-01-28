import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/payment_history_page.dart';
import 'home_page.dart';
import 'upload.dart';
import './notification_page.dart';

class MainScaffold extends StatefulWidget {
  final int selectedIndex;

  const MainScaffold({super.key, this.selectedIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;
  String userInitial = "A";
  String? userEmail;

  final List<Widget> _pages = [
    HomePage(),
    UploadPage(key: UniqueKey()),
    const NotificationPage(), // ✅ Notifications Page
    const OrderHistoryPage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _currentIndex = widget.selectedIndex;
    _loadUserDetails();

    // ✅ Listen to Firebase Notification Tap and Foreground Message
    NotificationPage.initializeFCM(context, () {
      setState(() {
        _currentIndex = 2; // index of NotificationPage
      });
    });
  }

  // 🔐 Check if user is logged in
  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (!isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  // 📩 Load user email & initials
  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail =
          prefs.getString('userPhone') ?? "Unknown"; // Displaying phone as ID
      String name = prefs.getString('userName') ?? "User";
      userInitial = name.isNotEmpty ? name[0].toUpperCase() : "U";
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12.0, bottom: 1, top: 10),
                child: CircleAvatar(
                  backgroundImage: AssetImage('assets/Xeroxshoplogo.jpg'),
                  radius: 20,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 1, top: 10),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: 'RIT Arcade'),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: Transform.translate(
                          offset: Offset(0, 4), // Subscript offset
                          child: Text(
                            ' RS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 1, top: 10),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 16,
                  child: Text(
                    userInitial,
                    style: TextStyle(
                      color: Colors.indigo[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(userEmail ?? "No email found"),
                    ),
                  );
                } else if (value == 'logout') {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.clear(); // Or specifically remove login keys
                  Navigator.pushReplacementNamed(context, '/login');
                } else if (value == 'contact') {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Contact Us'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 0),
                              leading: const Icon(Icons.email),
                              title: const Text('ritarcadeonline@gmail.com'),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () {
                                  Clipboard.setData(const ClipboardData(
                                      text: 'ritarcadeonline@gmail.com'));
                                },
                              ),
                            ),
                            ListTile(
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 0),
                              leading: const Icon(Icons.phone),
                              title: const Text('+91 97100 77795'),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () {
                                  Clipboard.setData(const ClipboardData(
                                      text: '+91 97100 77795'));
                                },
                              ),
                            ),
                            const ListTile(
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 0),
                              leading: Icon(Icons.location_on),
                              title: Text('RIT Campus, Chennai'),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Close'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'profile', child: Text('My Profile')),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
                const PopupMenuItem(value: 'contact', child: Text('Contact'))
              ],
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            backgroundColor: Color(0xFF6EACDA),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.black,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.upload), label: "Upload"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.notifications), label: "Notifications"),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: "Orders"),
            ],
          ),
        ),
      ),
    );
  }
}
