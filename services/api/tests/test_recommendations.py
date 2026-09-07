"""The reviewed adaptation loop.

A real session must be able to produce an explained proposal, and a caregiver
decision must be the only thing that changes what the patient plays next.
"""

from __future__ import annotations

from tests.helpers import play_full_session, route_quest_events


def _play_clean(client, caregiver, patient_id, count: int, **overrides) -> None:
    for _ in range(count):
        play_full_session(client, caregiver, patient_id, **overrides)


def _pending(client, caregiver, patient_id) -> list[dict]:
    body = client.get(
        f"/v1/patients/{patient_id}/recommendations?status=pending", headers=caregiver
    ).json()
    return body["items"]


class TestWhenNothingShouldHappen:
    def test_one_session_does_not_produce_a_proposal(self, client, caregiver, patient_id):
        play_full_session(client, caregiver, patient_id)
        assert _pending(client, caregiver, patient_id) == []

    def test_two_sessions_are_still_insufficient(self, client, caregiver, patient_id):
        _play_clean(client, caregiver, patient_id, 2)
        assert _pending(client, caregiver, patient_id) == []

    def test_assisted_sessions_never_promote(self, client, caregiver, patient_id):
        # Help used every time: excluded from the comparable series, so the
        # promotion path can never see three clean sessions.
        for _ in range(4):
            play_full_session(
                client, caregiver, patient_id, events=route_quest_events(hints=1), assisted=True
            )
        proposals = _pending(client, caregiver, patient_id)
        assert all(p["proposed_config"]["level"] <= 1 for p in proposals)

    def test_tutorial_sessions_are_excluded_from_the_series(
        self, client, caregiver, patient_id
    ):
        _play_clean(client, caregiver, patient_id, 3, is_tutorial=True)
        assert _pending(client, caregiver, patient_id) == []

    def test_interrupted_sessions_do_not_promote(self, client, caregiver, patient_id):
        for _ in range(3):
            play_full_session(
                client, caregiver, patient_id,
                events=route_quest_events(completed=False), status="interrupted",
            )
        promoted = [
            p
            for p in _pending(client, caregiver, patient_id)
            if p["proposed_config"]["level"] > 1
        ]
        assert promoted == []

    def test_changing_the_configuration_starts_a_new_series(
        self, client, caregiver, patient_id
    ):
        # Two sessions at one difficulty, then one at another: not three
        # comparable sessions, so no proposal.
        _play_clean(client, caregiver, patient_id, 2)
        play_full_session(
            client, caregiver, patient_id,
            difficulty_params={"nodeCount": 9, "branchCount": 3, "requiresReturn": True},
        )
        assert _pending(client, caregiver, patient_id) == []


class TestPromotion:
    def test_three_clean_sessions_propose_the_next_level(self, client, caregiver, patient_id):
        _play_clean(client, caregiver, patient_id, 3)
        proposals = _pending(client, caregiver, patient_id)
        assert len(proposals) == 1
        proposal = proposals[0]
        assert proposal["proposed_config"]["level"] == 2
        assert proposal["current_config"]["level"] == 1
        assert proposal["reason"]["code"] == "consistent_success"

    def test_the_proposal_explains_itself(self, client, caregiver, patient_id):
        _play_clean(client, caregiver, patient_id, 3)
        reason = _pending(client, caregiver, patient_id)[0]["reason"]
        assert len(reason["observed"]["session_ids"]) == 3
        assert reason["observed"]["objective_metric"] == "route_completed"
        assert reason["observed"]["hints_used"] == [0, 0, 0]
        assert reason["thresholds_used"]["promote_required_completions"] == 3

    def test_thresholds_are_labelled_as_unreviewed(self, client, caregiver, patient_id):
        # A caregiver-facing screen must not be able to present these as
        # validated by omission.
        _play_clean(client, caregiver, patient_id, 3)
        reason = _pending(client, caregiver, patient_id)[0]["reason"]
        assert reason["thresholds_status"] == "prototype_unreviewed"
        assert "not clinically reviewed" in reason["thresholds_note"]
        assert reason["rule_version"] == "rules-v1"

    def test_only_one_pending_proposal_at_a_time(self, client, caregiver, patient_id):
        _play_clean(client, caregiver, patient_id, 5)
        assert len(_pending(client, caregiver, patient_id)) == 1


class TestCaregiverDecision:
    def _proposal(self, client, caregiver, patient_id) -> dict:
        _play_clean(client, caregiver, patient_id, 3)
        return _pending(client, caregiver, patient_id)[0]

    def test_a_pending_proposal_does_not_change_what_the_patient_plays(
        self, client, caregiver, patient_id
    ):
        self._proposal(client, caregiver, patient_id)
        activity = client.get(f"/v1/patients/{patient_id}/activity", headers=caregiver).json()
        assert activity["level"] == 1
        assert activity["source"] == "safe_default"

    def test_accepting_activates_the_new_configuration(self, client, caregiver, patient_id):
        proposal = self._proposal(client, caregiver, patient_id)
        response = client.post(
            f"/v1/recommendations/{proposal['recommendation_id']}/decision",
            headers=caregiver,
            json={"decision": "accept"},
        )
        assert response.status_code == 200
        assert response.json()["status"] == "accepted"

        activity = client.get(f"/v1/patients/{patient_id}/activity", headers=caregiver).json()
        assert activity["level"] == 2
        assert activity["source"] == "approved"

    def test_rejecting_leaves_the_activity_untouched(self, client, caregiver, patient_id):
        proposal = self._proposal(client, caregiver, patient_id)
        client.post(
            f"/v1/recommendations/{proposal['recommendation_id']}/decision",
            headers=caregiver,
            json={"decision": "reject"},
        )
        activity = client.get(f"/v1/patients/{patient_id}/activity", headers=caregiver).json()
        assert activity["level"] == 1
        assert activity["source"] == "safe_default"

    def test_modifying_applies_the_caregivers_choice_not_the_proposal(
        self, client, caregiver, patient_id
    ):
        proposal = self._proposal(client, caregiver, patient_id)
        client.post(
            f"/v1/recommendations/{proposal['recommendation_id']}/decision",
            headers=caregiver,
            json={"decision": "modify", "modified_config": {"level": 1}},
        )
        activity = client.get(f"/v1/patients/{patient_id}/activity", headers=caregiver).json()
        assert activity["level"] == 1
        assert activity["source"] == "approved"

    def test_modify_without_a_configuration_is_refused(self, client, caregiver, patient_id):
        proposal = self._proposal(client, caregiver, patient_id)
        response = client.post(
            f"/v1/recommendations/{proposal['recommendation_id']}/decision",
            headers=caregiver,
            json={"decision": "modify"},
        )
        assert response.status_code == 422

    def test_a_proposal_cannot_be_decided_twice(self, client, caregiver, patient_id):
        proposal = self._proposal(client, caregiver, patient_id)
        url = f"/v1/recommendations/{proposal['recommendation_id']}/decision"
        client.post(url, headers=caregiver, json={"decision": "accept"})
        again = client.post(url, headers=caregiver, json={"decision": "reject"})
        assert again.status_code == 409
        assert again.json()["error"]["code"] == "already_decided"

    def test_a_stale_proposal_cannot_overwrite_a_newer_configuration(
        self, client, caregiver, patient_id
    ):
        proposal = self._proposal(client, caregiver, patient_id)
        # The caller believes the config version is still 0, but something has
        # moved it on since. Refuse rather than silently overwrite.
        response = client.post(
            f"/v1/recommendations/{proposal['recommendation_id']}/decision",
            headers=caregiver,
            json={"decision": "accept", "expected_config_version": 7},
        )
        assert response.status_code == 409
        assert response.json()["error"]["code"] == "revision_conflict"

    def test_another_caregiver_cannot_decide(self, client, caregiver, other_caregiver, patient_id):
        proposal = self._proposal(client, caregiver, patient_id)
        response = client.post(
            f"/v1/recommendations/{proposal['recommendation_id']}/decision",
            headers=other_caregiver,
            json={"decision": "accept"},
        )
        assert response.status_code == 403


class TestCeiling:
    def test_a_patient_at_the_top_level_is_not_promoted(self, client, caregiver, patient_id):
        # Approve level 3 (the registered ceiling for route_quest) first.
        _play_clean(client, caregiver, patient_id, 3)
        proposal = _pending(client, caregiver, patient_id)[0]
        client.post(
            f"/v1/recommendations/{proposal['recommendation_id']}/decision",
            headers=caregiver,
            json={"decision": "modify", "modified_config": {"level": 3}},
        )

        _play_clean(client, caregiver, patient_id, 3, level=3)
        assert _pending(client, caregiver, patient_id) == []


class TestEasing:
    def test_repeatedly_unfinished_sessions_hold_at_the_gentlest_level(
        self, client, caregiver, patient_id
    ):
        # Already at level 1, which is the floor: the rules must not propose
        # level 0, and must not crash trying.
        for _ in range(3):
            play_full_session(
                client, caregiver, patient_id,
                events=route_quest_events(completed=False), status="stopped_by_user",
            )
        assert _pending(client, caregiver, patient_id) == []

    def test_difficulty_at_a_higher_level_proposes_an_easier_one(
        self, client, caregiver, patient_id
    ):
        _play_clean(client, caregiver, patient_id, 3)
        proposal = _pending(client, caregiver, patient_id)[0]
        client.post(
            f"/v1/recommendations/{proposal['recommendation_id']}/decision",
            headers=caregiver,
            json={"decision": "accept"},
        )

        for _ in range(3):
            play_full_session(
                client, caregiver, patient_id, level=2,
                events=route_quest_events(completed=False), status="stopped_by_user",
            )

        pending = _pending(client, caregiver, patient_id)
        assert len(pending) == 1
        assert pending[0]["proposed_config"]["level"] == 1
        assert pending[0]["reason"]["code"] == "repeated_difficulty"
