import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:toast/toast.dart';

void main() {
  runApp(MaterialApp(
    home: HomeScreen(),
  ));
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  int highlightPos;
  double _contactWidgetSize = 70.0;

  @override
  void initState() {
    _checkPerm();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          margin: EdgeInsets.only(left: 16),
          alignment: Alignment.bottomLeft,
          child: Text(
            'Contacts',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 28),
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Field
            Container(
              margin: EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.centerLeft,
              width: MediaQuery.of(context).size.width / 1.5,
              child: CupertinoTextField(
                controller: _searchController,
                padding: EdgeInsets.symmetric(horizontal: 12),
                placeholder: 'Search people',
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    color: Colors.grey.withOpacity(.15)),
                suffix: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _filteredContacts = [];
                    _contacts.forEach((_c) {
                      if (_c.displayName
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase())) {
                        _filteredContacts.add(_c);
                      }
                    });
                    setState(() {});
                  },
                  iconSize: 24,
                  icon: Icon(Icons.search),
                  color: Colors.grey,
                ),
              ),
            ),

            _contactsList(_filteredContacts.isNotEmpty ? _filteredContacts : _contacts),

            Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cancel button
                MaterialButton(
                  onPressed: () {
                    // Clear text
                    _searchController.clear();
                    _filteredContacts = [];
                    setState(() {});
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.close,
                        color: Colors.grey,
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 8),
                        child: Text(
                          'cancel',
                          style: TextStyle(color: Colors.grey, fontSize: 17),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  margin: EdgeInsets.only(right: 12, bottom: 12),
                  child: FloatingActionButton(
                    onPressed: () {
                      List<Contact> _conts =
                          _filteredContacts.isNotEmpty ? _filteredContacts : _contacts;

                      _conts.forEach((_c) {
                        if (_c.displayName.trim().toLowerCase() ==
                            _searchController.text.trim().toLowerCase()) {
                          // Go to offset

                          _scrollController.animateTo(_conts.indexOf(_c) * _contactWidgetSize,
                              duration: Duration(milliseconds: 400), curve: Curves.linear);
                          highlightPos = _conts.indexOf(_c);
                          setState(() {});
                          return;
                        }
                      });

                      if (highlightPos != null) {
                        Timer.periodic(Duration(seconds: 1), (timer) {
                          if (mounted) {
                            setState(() {
                              highlightPos = null;
                            });
                          }
                          timer.cancel();
                        });
                      }
                    },
                    child: Icon(
                      Icons.done,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _contactsList(List<Contact> _contacts) {
    return Expanded(
      child: _contacts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              itemCount: _contacts.length,
              itemBuilder: (context, pos) {
                return AnimatedContainer(
                  height: _contactWidgetSize,
                  duration: Duration(milliseconds: 1000),
                  color: highlightPos == pos ? Colors.blue.withOpacity(.5) : Colors.transparent,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: ClipOval(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                color: Colors.blue,
                              ),
                              Text(
                                _contacts[pos].displayName[0],
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              )
                            ],
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              child: Text(
                                _contacts[pos].displayName,
                              )),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            child: Text(_contacts[pos].phones.isNotEmpty
                                ? _contacts[pos].phones.first.value.toString()
                                : 'No phone number yet...'),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _checkPerm() async {
    try {
      // Get the permission status
      var status = await Permission.contacts.status;

      if (status.isUndetermined) {
        await Permission.contacts.request();

        // If granted
        if (status.isGranted) {
          _contacts = List.from(await ContactsService.getContacts());
        }
      } else if (status.isGranted) {
        _contacts = List.from(await ContactsService.getContacts());

        setState(() {});
      } else {
        Toast.show('Please grant permission to the contacts.', this.context);
      }
    } catch (e) {
      print(e);
    }
  }
}
