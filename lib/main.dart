import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config.dart'; // Import your config file

// Load the API URL from the .env file and assign it to a global variable
//final String apiUrl = dotenv.env['API_URL_DEV'] ?? "localhost:3001";
Future main() async {
  await dotenv.load(fileName: ".env");
  initializeConfig(); // Initialize your global variable after dotenv is loaded
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laboratoires MacOS',
      home: LabListPage(),
      //home: LoginPage(),
    );
  }
}

class LabListPage extends StatefulWidget {
  @override
  _LabListPageState createState() => _LabListPageState();
}

class _LabListPageState extends State<LabListPage>
    with WidgetsBindingObserver {
  List<Lab> labs = [];

  @override
  void initState() {
    super.initState();
    _loadLabs();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveLabs();
    }
  }

  _loadLabs() async {
    final url = Uri.parse('$apiUrl/api/students/laboratoriesMachines');
    final response = await http.get(url, headers: {
      // Include any headers here if necessary, such as Authentication headers
    });

    if (response.statusCode == 200) {
      final List<dynamic> labsJson = json.decode(response.body);
      setState(() {
        labs = labsJson.map((labJson) => Lab.fromJson(labJson)).toList();
      });
    } else {
      // Handle error, perhaps by showing a Snackbar with the error message
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching labs')));
    }
  }

  _saveLabs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> labsJson = labs.map((lab) => jsonEncode(lab.toJson())).toList();
    prefs.setStringList('labs', labsJson);
  }

  @override
Widget build(BuildContext context) {
  
  Color mutedOrange = Color(0xFFFFAB91); // Muted Orange for App Bar
  Color deepGray = Color(0xFF424242); // Deep Gray for tiles
  Color lightGray = Color(0xFFF5F5F5); // Light Gray for background
  Color editButtonColor = Colors.blue; // Blue for edit button
  Color deleteButtonColor = Colors.red; // Red for delete button


  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Liste des laboratoires',
        style: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 20.0,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.orange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20.0),
        ),
      ),
      shadowColor: Colors.grey[800],
      actions: [
        IconButton(
          icon: Icon(Icons.sync),
          onPressed: () {
            _loadLabs();
          },
        ),
      ],
    ),
    backgroundColor: lightGray,
    body: Padding(
      padding: EdgeInsets.only(top: 8.0),
      child: ListView.separated(
        itemCount: labs.length,
        separatorBuilder: (BuildContext context, int index) {
          return Divider(
            color: Colors.grey[400],
            height: 1.0,
          );
        },
        itemBuilder: (context, index) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            color: deepGray,
            child: ListTile(
              contentPadding: EdgeInsets.all(8.0),
              title: Text(
                labs[index].name,
                style: TextStyle(color: Colors.white),
              ),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Icon(Icons.computer, size: 50.0, color: Colors.white), // Use appropriate icons for each lab type
              ),
              onTap: () {
                _navigateToLabMachinesPage(context, labs[index]);
              },
              onLongPress: () {
                _showEditLabDialog(context, labs[index]);
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: editButtonColor),
                    onPressed: () {
                      _showEditLabDialog(context, labs[index]);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_forever, color: deleteButtonColor),
                    onPressed: () {
                      _deleteLab(context, labs[index]);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        _showAddLabDialog(context);
      },
      backgroundColor: Colors.orange,
      child: Icon(Icons.add, color: Colors.white),
    ),
  );
}


void _showAddLabDialog(BuildContext context) {
  TextEditingController labNameController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Ajouter un nouveau laboratoire'),
        content: Column(
          mainAxisSize: MainAxisSize.min, // To prevent overflow when the keyboard appears
          children: [
            TextField(
              controller: labNameController,
              decoration: InputDecoration(labelText: 'Nom du laboratoire'),
            ),
            TextField(
              controller: locationController,
              decoration: InputDecoration(labelText: 'Emplacement du laboratoire'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              var newLab = {
                'name': labNameController.text,
                'location': locationController.text,
              };
              var url = Uri.parse('$apiUrl/api/professors/laboratories');
              var response = await http.post(url, body: jsonEncode(newLab), headers: {'Content-Type': 'application/json'});
              if (response.statusCode == 200 || response.statusCode == 201) {
                // Assuming you have a method to refresh your lab list
                _loadLabs();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Labo ajouté avec succès')));

              } else {
                // Handle errors here, possibly with a snackbar
              }
              Navigator.pop(context);
            },
            child: Text('Ajouter'),
          ),
        ],
      );
    },
  );
}


void _showEditLabDialog(BuildContext context, Lab lab) {
  TextEditingController labNameController =
      TextEditingController(text: lab.name);
  TextEditingController locationController =
      TextEditingController(text: lab.location);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Modifier le laboratoire'),
        content: SingleChildScrollView( // Use SingleChildScrollView to prevent overflow
          child: Column(
            mainAxisSize: MainAxisSize.min, // To prevent overflow when the keyboard appears
            children: [
              TextField(
                controller: labNameController,
                decoration: InputDecoration(labelText: 'Nom du laboratoire'),
              ),
              TextField(
                controller: locationController,
                decoration: InputDecoration(labelText: 'Emplacement du laboratoire'),
              ),
              // Removed the machines TextField since it's not required for the edit
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              var editedLab = {
                'name': labNameController.text,
                'location': locationController.text,
              };
              // Use the lab's id in the URL
              var url = Uri.parse('$apiUrl/api/professors/laboratories/${lab.id}');
              var response = await http.put(url, body: jsonEncode(editedLab), headers: {'Content-Type': 'application/json'});
              if (response.statusCode == 200) {
                // If the update was successful, refresh the lab list
                _loadLabs();
              } else {
                // Handle errors here
              }
              Navigator.pop(context);
            },
            child: Text('Enregistrer'),
          ),
        ],
      );
    },
  );
}


  void _navigateToLabMachinesPage(BuildContext context, Lab lab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LabMachinesPage(lab: lab,onLabsUpdated: _loadLabs),
      ),
    );
  }

void _deleteLab(BuildContext context, Lab lab) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Supprimer le laboratoire'),
        content: Text('Voulez-vous vraiment supprimer ${lab.name}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              // The URL includes the lab's id.
              var url = Uri.parse('$apiUrl/api/professors/laboratories/${lab.id}');
              var response = await http.delete(url);

              if (response.statusCode == 200) {
                setState(() {
                  labs.removeWhere((item) => item.id == lab.id);
                });
                // Assuming _loadLabs() is your method to reload the lab list from the server.
                _loadLabs();
              } else {
                // Handle errors here. For example, show an error message to the user.
              }

              Navigator.pop(context);
            },
            child: Text('Supprimer'),
          ),
        ],
      );
    },
  );
}

}

class Lab {
  final String id;
  final String name;
  final String location;
  final List<Machine> machines;

  Lab({required this.id, required this.name, required this.location, required this.machines});

factory Lab.fromJson(Map<String, dynamic> json) {
  // Provide an empty list as a fallback if json['machines'] is null.
  var machinesList = (json['machines'] as List? ?? []).map((machineJson) => Machine.fromJson(machineJson)).toList();
  return Lab(
    id: json['_id'] as String,
    name: json['name'] as String,
    location: json['location'] as String,
    machines: machinesList,
  );
}

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'location': location,
      'machines': machines.map((machine) => machine.toJson()).toList(),
    };
  }
}

class Machine {
  final String id;
  final String identifier;
  final String status;
  final String operatingSystem;

  Machine({required this.id,required this.identifier, required this.status,required this.operatingSystem});

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['_id'],
      identifier: json['identifier'],
      status: json['status'],
      operatingSystem: json['operating_system'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operating_system':operatingSystem,
      'identifier': identifier,
      'status': status,
    };
  }
}

class LabMachinesPage extends StatefulWidget {
  final Lab lab;
  final VoidCallback onLabsUpdated; // Callback function


  LabMachinesPage({required this.lab, required this.onLabsUpdated});

  @override
  _LabMachinesPageState createState() => _LabMachinesPageState();
}



class _LabMachinesPageState extends State<LabMachinesPage> {
  List<Machine> machines = []; 
  @override
  void initState() {
    super.initState();
    _loadMachinesForLab();

  }
_loadMachinesForLab() async {
    final url = Uri.parse('$apiUrl/api/students/laboratories/${widget.lab.id}/machines');
    final response = await http.get(url, headers: {
      // Include any headers here if necessary, such as Authentication headers
    });

    if (response.statusCode == 200) {
      final List<dynamic> machinesJson = json.decode(response.body);
      setState(() {
        machines = machinesJson.map((machineJson) => Machine.fromJson(machineJson)).toList();
      });
    } else {
      // Handle error, perhaps by showing a Snackbar with the error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching machines')));
    }
  }


void _showAddMachineDialog(BuildContext context, Lab lab) {
  TextEditingController machineNameController = TextEditingController();
  TextEditingController labNameController = TextEditingController(text: lab.name);
  String selectedStatus = 'Available'; // Default status
  final List<String> operatingSystems = [
    'Windows 10', 'Windows 11', 'macOS Monterey', 'macOS Big Sur',
    'Ubuntu', 'Debian', 'Fedora', 'Linux Mint', 'Red Hat Enterprise Linux', 'CentOS',
  ]; // List of operating systems
  String selectedOS = operatingSystems.first; // Default OS

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Ajouter une nouvelle machine'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                            TextField(
                controller: labNameController,
                decoration: InputDecoration(labelText: 'Laboratoire'),
                enabled: false, // Greyed out
              ),
              TextField(
                controller: machineNameController,
                decoration: InputDecoration(labelText: 'Nom de la machine'),
              ),

Row(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    Text('Status: ', style: TextStyle(fontWeight: FontWeight.normal)), // Static text in front of the DropdownButton
    DropdownButton<String>(
      value: selectedStatus,
      onChanged: (String? newValue) {
        setState(() {
          selectedStatus = newValue!;
        });
      },
      items: <String>['Available', 'In Use', "Maintenance"]
          .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
    ),
  ],
),

             Autocomplete<String>(
  optionsBuilder: (TextEditingValue textEditingValue) {
    if (textEditingValue.text.isEmpty) {
      return const Iterable<String>.empty();
    } else {
      return operatingSystems.where((String option) {
        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
      });
    }
  },
  onSelected: (String selection) {
    selectedOS = selection;
  },
  fieldViewBuilder: (
    BuildContext context,
    TextEditingController fieldTextEditingController,
    FocusNode fieldFocusNode,
    VoidCallback onFieldSubmitted,
  ) {
    return TextField(
      controller: fieldTextEditingController,
      focusNode: fieldFocusNode,
      decoration: InputDecoration(
        labelText: 'Operating System', // Use this to set the label text
        //hintText: 'Select an operating system', // Use this to set the hint text
      ),
      style: TextStyle(fontWeight: FontWeight.bold), // Optional text style
      onSubmitted: (String value) {
        onFieldSubmitted();
      },
    );
  },
),

            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              var newMachine = {
                "identifier": machineNameController.text,
                "status": selectedStatus,
                "operating_system": selectedOS,
                "lab_id": lab.id,
              };
              var url = Uri.parse('$apiUrl/api/professors/machine');
              var response = await http.post(url, body: jsonEncode(newMachine), headers: {'Content-Type': 'application/json'});
              if (response.statusCode == 201) {
                // Assuming you have a method to refresh the machines list
                
                _loadMachinesForLab();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Machine ajoutée avec succès')));

              } else {
                // Handle error
              }
              Navigator.pop(context);
            },
            child: Text('Ajouter'),
          ),
        ],
      );
    },
  );
}





void deleteMachine(BuildContext context, Machine machine) {
  // Show confirmation dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Supprimer la machine'),
        content: Text('Voulez-vous vraiment supprimer ${machine.identifier}?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close the dialog
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              // API call to delete the machine
              final url = Uri.parse('$apiUrl/api/professors/machine/${machine.id}');
              final response = await http.delete(url);

              // Close the dialog
              Navigator.of(context).pop();

              if (response.statusCode == 200) {
                // Optionally, refresh the machines list or show a success message
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Machine supprimée avec succès')));
                // If you have a function to refresh the list of machines, call it here
                _loadMachinesForLab();
              } else {
                // Handle errors here, such as showing an error message
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression de la machine')));
              }
            },
            child: Text('Supprimer'),
          ),
        ],
      );
    },
  );
}

void _showEditMachineDialog(BuildContext context, Lab lab, Machine machine) {
  TextEditingController machineNameController = TextEditingController(text: machine.identifier);
  TextEditingController labNameController = TextEditingController(text: lab.name);
  String selectedStatus = machine.status; // Pre-fill with the current status
  final List<String> operatingSystems = [
    'Windows 10', 'Windows 11', 'macOS Monterey', 'macOS Big Sur',
    'Ubuntu', 'Debian', 'Fedora', 'Linux Mint', 'Red Hat Enterprise Linux', 'CentOS',
  ]; // List of operating systems
  String selectedOS = machine.operatingSystem; // Pre-fill with the current OS

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Modifier la machine'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: machineNameController,
                decoration: InputDecoration(labelText: 'Nom de la machine'),
              ),
              TextField(
                controller: labNameController,
                decoration: InputDecoration(labelText: 'Labo'),
                enabled: false, // Greyed out
              ),
              DropdownButton<String>(
                value: selectedStatus,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedStatus = newValue!;
                  });
                },
                items: <String>['Available', 'In Use', 'Maintenance']
                    .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
              ),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  } else {
                    return operatingSystems.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  }
                },
                onSelected: (String selection) {
                  selectedOS = selection;
                },
                initialValue: TextEditingValue(text: selectedOS), // Pre-fill the autocomplete with the current OS
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              var updatedMachine = {
                "identifier": machineNameController.text,
                "status": selectedStatus,
                "operating_system": selectedOS,
                "lab_id": lab.id,
              };
              var url = Uri.parse('$apiUrl/api/professors/machine/${machine.id}');
              var response = await http.put(url, body: jsonEncode(updatedMachine), headers: {'Content-Type': 'application/json'});
              if (response.statusCode == 200) {
                // Refresh the machines list
                Navigator.pop(context); // Close the dialog
                _loadMachinesForLab();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Machine modifiée avec succès')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la modification de la machine')));
              }
            },
            child: Text('Enregistrer'),
          ),
        ],
      );
    },
  );
}


@override
Widget build(BuildContext context) {
  Widget bodyContent;

  Color availableColor = Colors.lightGreenAccent[100] ?? Colors.lightGreenAccent;
  Color inUseColor = Colors.redAccent[100] ?? Colors.redAccent;
  Color editColor = Colors.blue; // Blue color for edit
  Color deleteColor = Colors.red; // Red color for delete

  // Determine the body content based on whether the machines list is empty
  if (machines.isEmpty) {
    bodyContent = Center(
      child: Text('No machines available'),
    );
  } else {
    bodyContent = ListView.builder(
      itemCount: machines.length,
      itemBuilder: (context, index) {
        Machine machine = machines[index];
    IconData osIcon = Icons.device_unknown; // Default icon

    String osLowerCase = machine.operatingSystem.toLowerCase();

    if (osLowerCase.contains('windows')) {
      osIcon = Icons.laptop_windows;
    } else if (osLowerCase.contains('macos') || osLowerCase.contains('mac')) {
      osIcon = Icons.laptop_mac; // Using MacBook icon for Mac
    } else if (osLowerCase.contains('ubuntu') || osLowerCase.contains('debian') || osLowerCase.contains('fedora') ||
               osLowerCase.contains('linux') || osLowerCase.contains('centos') || osLowerCase.contains('red hat')) {
      osIcon = Icons.settings_system_daydream; // Stand-in for Linux
    }


        Color bgColor = machine.status == 'Available' ? availableColor : inUseColor; // Background color based on status

    return Container(
       margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Adds space around each container
      //color: bgColor, // Use the bgColor for the ListTile
          decoration: BoxDecoration(
      //color: bgColor, // Background color from your logic
      borderRadius: BorderRadius.circular(10.0), // Rounded corners
      boxShadow: [
        BoxShadow(
          color: bgColor,
          blurRadius: 1,
          offset: Offset(2, 2), // Shadow position
        ),
      ],
    ),
      child: ListTile(
        leading: Icon(osIcon), // Displaying the OS icon
        title: Text('${machine.identifier} - ${machine.operatingSystem}'),
        subtitle: Text('Status: ${machine.status}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: editColor),
              onPressed: () {
                // Logic to edit machine
                _showEditMachineDialog(context, widget.lab, machine);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: deleteColor),
              onPressed: () {
                // Logic to delete machine
                deleteMachine(context, machine);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build the Scaffold with the AppBar and FloatingActionButton once, using the determined body content
  return Scaffold(
    appBar: AppBar(
      title: Text('${widget.lab.name}',
        style: TextStyle(
          //fontWeight: FontWeight.bold,
          fontWeight: FontWeight.normal,
          fontSize: 20.0,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.orange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20.0),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () {
            _loadMachinesForLab();
          },
        ),
      ],
    ),
    body: bodyContent,
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        _showAddMachineDialog(context, widget.lab);
      },
      backgroundColor: Colors.orange,
      child: Icon(Icons.add),
    ),
  );
}


}



class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _performLogin(BuildContext context) async {
    final url = Uri.parse('$apiUrl/api/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Assuming status code 200 means login success
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Login Successful'),
            content: Text('You have successfully logged in.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );

        // Navigate to the LabListPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LabListPage()), // Replace with your LabListPage
        );
      } else {
        // Handle error response (e.g., 400 or 401)
        final responseData = json.decode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Login Failed'),
            content: Text(responseData['message'] ?? 'Invalid credentials'), // Or any other error message handling
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Handle any errors that occur during the POST request
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('An error occurred. Please try again later.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
        ),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: emailController, // Attach the emailController here
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController, // Attach the passwordController here
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
  child: Text('Login'),
 onPressed: () => _performLogin(context),
              style: ElevatedButton.styleFrom(
                backgroundColor : Colors.orange,
                foregroundColor : Colors.white,
              ),
            ),
            TextButton(
              child: Text('Don\'t have an account? Sign up'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignupPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String status = 'Student'; // Default to 'Student'

  Future<void> _performSignUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      _showDialog('Error', 'Passwords do not match');
      return;
    }

    
    final url = Uri.parse('$apiUrl/api/users');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'status': status,
      }),
    );

    if (response.statusCode == 201) {
      _showDialog('Success', 'Sign up successful', navigateToLogin: true);
    } else {
      _showDialog('Error', 'Failed to sign up');
    }
  }

  void _showDialog(String title, String content, {bool navigateToLogin = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (navigateToLogin) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              }
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sign Up',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
        ),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('Student'),
              leading: Radio<String>(
                value: 'Student',
                groupValue: status,
                onChanged: (value) {
                  setState(() {
                    status = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: Text('Professor'),
              leading: Radio<String>(
                value: 'Professor',
                groupValue: status,
                onChanged: (value) {
                  setState(() {
                    status = value!;
                  });
                },
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              child: Text('Sign Up'),
              onPressed: _performSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            Center(
              child: TextButton(
                child: Text('Already have an account? Login'),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()), // Replace with your LoginPage
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

