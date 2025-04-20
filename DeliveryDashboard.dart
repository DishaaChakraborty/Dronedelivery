// delivery_dashboard.dart - Main User Interface
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/drone_coordinator.dart';
import 'services/obstacle_detector.dart';
import 'services/route_planner.dart';
import 'models/delivery_task.dart'; // Assuming this model exists

// --- Placeholder Model & Enum (Move to models/delivery_task.dart later) ---
// You should have a proper models/delivery_task.dart file.
// These are placeholders if you don't have them yet.
enum DeliveryStatus { pending, assigned, enRoute, delivered, failed, returning }

class DeliveryTask {
  final String id;
  final String pickupLocation;
  final String dropoffLocation;
  DeliveryStatus status;
  String? assignedDroneId; // Example extra field

  DeliveryTask({
    required this.id,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.status = DeliveryStatus.pending,
    this.assignedDroneId,
  });

  @override
  String toString() {
    return 'DeliveryTask(id: $id, from: $pickupLocation, to: $dropoffLocation, status: $status)';
  }
}
// --- End Placeholder Model & Enum ---


class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {

  // Example function to trigger a new delivery task
  void _startNewDelivery() {
    // Use context.read inside callbacks for one-off actions
    final droneCoordinator = context.read<DroneCoordinator>();
    final routePlanner = context.read<RoutePlanner>();

    // Create a dummy task - replace with data from a form or other source
    final newTask = DeliveryTask(
      id: 'TASK-${DateTime.now().millisecondsSinceEpoch}',
      pickupLocation: 'Warehouse A',
      dropoffLocation: 'Customer Location ${DateTime.now().second}',
      status: DeliveryStatus.pending,
    );

    print("Dashboard: Attempting to create task: ${newTask.id}");

    try {
      // 1. Plan the route (optional, coordinator might do this)
      // Assuming RoutePlanner has a method like this:
      // routePlanner.planRoute(newTask.pickupLocation, newTask.dropoffLocation);

      // 2. Assign the task via the coordinator
      // Assuming DroneCoordinator has a method like this:
      droneCoordinator.assignTask(newTask);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New delivery task ${newTask.id} created.')),
      );
    } catch (e) {
       print("Dashboard: Error starting delivery: $e");
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting delivery: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use context.watch to listen for changes in providers and rebuild UI
    final droneCoordinator = context.watch<DroneCoordinator>();
    final obstacleDetector = context.watch<ObstacleDetector>();
    final routePlanner = context.watch<RoutePlanner>();

    // Get the list of tasks from the coordinator
    // Assumes DroneCoordinator has a getter `deliveryTasks` like:
    // List<DeliveryTask> get deliveryTasks => _tasks; (where _tasks is a list)
    final List<DeliveryTask> tasks = droneCoordinator.deliveryTasks; // Needs implementation in DroneCoordinator

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drone Delivery Dashboard'),
        actions: [
          // Example: Show obstacle detection status
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              // Assumes ObstacleDetector has a bool property `hasObstacles`
              child: Icon(
                obstacleDetector.hasObstacles ? Icons.warning : Icons.security, // Needs impl in ObstacleDetector
                color: obstacleDetector.hasObstacles ? Colors.orange : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Service Status Section (Example) ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text("System Status", style: Theme.of(context).textTheme.titleMedium),
                     const SizedBox(height: 8),
                     // Assumes DroneCoordinator has a status getter like:
                     // String get overallStatus => _status;
                     Text('Coordinator: ${droneCoordinator.overallStatus}'), // Needs impl in DroneCoordinator
                     // Assumes RoutePlanner has a status getter like:
                     // String get plannerStatus => _status;
                     Text('Route Planner: ${routePlanner.plannerStatus}'), // Needs impl in RoutePlanner
                     // Assumes ObstacleDetector has a status getter like:
                     // String get detectorStatus => _status;
                     Text('Obstacle Detector: ${obstacleDetector.detectorStatus}'), // Needs impl in ObstacleDetector
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Delivery Tasks Section ---
            Text(
              'Delivery Tasks (${tasks.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(child: Text('No delivery tasks yet.'))
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return ListTile(
                          leading: Icon(_getIconForStatus(task.status)),
                          title: Text('Task ID: ${task.id}'),
                          subtitle: Text(
                              'To: ${task.dropoffLocation} - Status: ${task.status.name} ${task.assignedDroneId != null ? "(Drone: ${task.assignedDroneId})" : "" }'
                           ),
                           trailing: IconButton(
                             icon: const Icon(Icons.info_outline),
                             onPressed: () {
                               // Show more details about the task
                               _showTaskDetails(context, task);
                             },
                           ),
                          isThreeLine: task.assignedDroneId != null, // Adjust layout if drone assigned
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewDelivery,
        icon: const Icon(Icons.add),
        label: const Text('New Delivery'),
      ),
    );
  }

  // Helper to get an icon based on delivery status
  IconData _getIconForStatus(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Icons.pending_actions;
      case DeliveryStatus.assigned:
        return Icons.assignment_ind;
      case DeliveryStatus.enRoute:
        return Icons.flight_takeoff;
      case DeliveryStatus.delivered:
        return Icons.check_circle_outline;
      case DeliveryStatus.failed:
        return Icons.error_outline;
       case DeliveryStatus.returning:
        return Icons.flight_land;
      default:
        return Icons.help_outline;
    }
  }

  // Example dialog to show more task details
  void _showTaskDetails(BuildContext context, DeliveryTask task) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Task Details: ${task.id}'),
        content: SingleChildScrollView( // Use SingleChildScrollView if content might overflow
          child: ListBody( // Use ListBody for simple vertical list
            children: <Widget>[
              Text('Status: ${task.status.name}'),
              Text('Pickup: ${task.pickupLocation}'),
              Text('Dropoff: ${task.dropoffLocation}'),
              if (task.assignedDroneId != null)
                Text('Assigned Drone: ${task.assignedDroneId}'),
              // Add more details here: timestamps, package info, etc.
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}