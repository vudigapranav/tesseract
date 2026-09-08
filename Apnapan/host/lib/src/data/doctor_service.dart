import 'api_client.dart';

/// Doctor-side reads, against the assignment-controlled backend routes.
///
/// Everything here is scoped server-side by doctor assignment: the API returns
/// only patients this doctor is assigned to, and a direct patient id the
/// doctor is not assigned to is refused with 403. Nothing in this class can
/// widen that — there is no client-side patient list to bypass.
///
/// A doctor **reads**. There is no method here that records gameplay or
/// approves an activity: caregiver approval remains the only path by which a
/// patient's activity changes, which is the authority policy recorded in the
/// build handbook.
class DoctorService {
  DoctorService(this.api);

  final ApiClient api;

  /// Patients assigned to the signed-in doctor.
  Future<List<Map<String, dynamic>>> assignedPatients() async {
    final Map<String, dynamic> response =
        await api.request('GET', '/v1/doctor/patients');
    return (response['items'] as List? ?? <Object?>[])
        .cast<Map<String, dynamic>>();
  }

  /// Observed application-performance summary for one assigned patient.
  ///
  /// The server decides what is comparable and what is unavailable; this does
  /// not recompute anything, so the doctor view and the caregiver view cannot
  /// disagree about the same sessions.
  Future<Map<String, dynamic>> summary(String patientId,
          {int windowDays = 30}) =>
      api.request('GET',
          '/v1/doctor/patients/$patientId/summary?window_days=$windowDays');

  Future<List<Map<String, dynamic>>> sessions(String patientId,
      {int limit = 50}) async {
    final Map<String, dynamic> response = await api.request(
        'GET', '/v1/patients/$patientId/sessions?limit=$limit');
    return (response['items'] as List? ?? <Object?>[])
        .cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> notes(String patientId) async {
    final Map<String, dynamic> response =
        await api.request('GET', '/v1/patients/$patientId/notes');
    return (response['items'] as List? ?? <Object?>[])
        .cast<Map<String, dynamic>>();
  }

  /// Notes are attributed to the signed-in doctor by the server, from the
  /// bearer token — never from anything sent here.
  Future<Map<String, dynamic>> addNote(String patientId, String body) =>
      api.request('POST', '/v1/patients/$patientId/notes',
          <String, Object?>{'body': body});

  /// Requests a generated draft. The server grounds it in stored sessions and
  /// records whether the text came from a template or a model.
  Future<Map<String, dynamic>> createReport(String patientId,
          {int windowDays = 30}) =>
      api.request('POST', '/v1/patients/$patientId/reports',
          <String, Object?>{'window_days': windowDays});
}
