import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sp_gallery/providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remotePathController = TextEditingController();
  bool _enabled = false;
  bool _autoSync = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _remotePathController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final settings = context.read<SettingsProvider>();
    final config = settings.rsyncConfig;
    
    _serverController.text = config.server;
    _usernameController.text = config.username;
    _passwordController.text = config.password;
    _remotePathController.text = config.remotePath;
    _enabled = config.enabled;
    _autoSync = config.autoSync;
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final config = RsyncConfig(
        server: _serverController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        remotePath: _remotePathController.text.trim(),
        enabled: _enabled,
        autoSync: _autoSync,
      );

      await context.read<SettingsProvider>().updateRsyncConfig(config);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rsync Configuration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rsync Configuration',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      
                      SwitchListTile(
                        title: const Text('Enable Rsync Sync'),
                        subtitle: const Text('Sync media to remote server'),
                        value: _enabled,
                        onChanged: (value) => setState(() => _enabled = value),
                      ),
                      
                      if (_enabled) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _serverController,
                          decoration: const InputDecoration(
                            labelText: 'Server Address',
                            hintText: 'example.com',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter server address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            hintText: 'username',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            hintText: 'password',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        TextFormField(
                          controller: _remotePathController,
                          decoration: const InputDecoration(
                            labelText: 'Remote Path',
                            hintText: '/path/to/backup',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter remote path';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        SwitchListTile(
                          title: const Text('Auto Sync'),
                          subtitle: const Text('Automatically sync when new media is added'),
                          value: _autoSync,
                          onChanged: (value) => setState(() => _autoSync = value),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _enabled ? _saveSettings : null,
                        child: const Text('Save Rsync Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // App Settings Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Settings',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    Consumer<SettingsProvider>(
                      builder: (context, settings, child) {
                        return SwitchListTile(
                          title: const Text('Dark Mode'),
                          subtitle: const Text('Toggle dark theme'),
                          value: settings.isDarkMode,
                          onChanged: (value) => settings.toggleDarkMode(),
                        );
                      },
                    ),
                    
                    Consumer<SettingsProvider>(
                      builder: (context, settings, child) {
                        return ListTile(
                          title: const Text('Grid Columns'),
                          subtitle: Text('Columns: ${settings.gridColumns}'),
                          trailing: DropdownButton<int>(
                            value: settings.gridColumns,
                            items: [2, 3, 4, 5].map((columns) {
                              return DropdownMenuItem(
                                value: columns,
                                child: Text('$columns'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                settings.updateGridColumns(value);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
