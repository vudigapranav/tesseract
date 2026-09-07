"""Patient profiles and Know Me content."""

from __future__ import annotations

import io


def test_creating_a_patient_grants_the_creator_membership(client, caregiver):
    created = client.post(
        "/v1/patients", headers=caregiver, json={"display_name": "Synthetic A"}
    )
    assert created.status_code == 201
    patient_id = created.json()["patient_id"]
    assert client.get(f"/v1/patients/{patient_id}", headers=caregiver).status_code == 200


def test_clinical_fields_are_optional(client, caregiver):
    response = client.post(
        "/v1/patients", headers=caregiver, json={"display_name": "Synthetic B"}
    )
    body = response.json()
    assert body["known_type"] is None
    assert body["known_stage"] is None


def test_clinical_fields_accept_unknown(client, caregiver):
    response = client.post(
        "/v1/patients",
        headers=caregiver,
        json={"display_name": "Synthetic C", "known_type": "unknown", "known_stage": "unknown"},
    )
    assert response.status_code == 201
    assert response.json()["known_type"] == "unknown"


class TestPersonalization:
    def test_words_and_people_are_stored(self, client, caregiver, patient_id):
        response = client.put(
            f"/v1/patients/{patient_id}/personalization",
            headers=caregiver,
            json={
                "version": 1,
                "personal_words": [{"text": "chai"}, {"text": "garden"}],
                "people_places": [{"kind": "person", "label": "Daughter"}],
                "preferences": {"prefers_images_over_words": True},
            },
        )
        assert response.status_code == 200
        assert response.json()["version"] == 2

        stored = client.get(
            f"/v1/patients/{patient_id}/personalization", headers=caregiver
        ).json()
        assert [w["text"] for w in stored["personal_words"]] == ["chai", "garden"]
        assert stored["people_places"][0]["label"] == "Daughter"
        assert stored["preferences"]["prefers_images_over_words"] is True

    def test_no_words_at_all_is_accepted(self, client, caregiver, patient_id):
        # 15-20 is a product target the client explains, not a rule the server
        # enforces. Skipping must work.
        response = client.put(
            f"/v1/patients/{patient_id}/personalization",
            headers=caregiver,
            json={"version": 1, "personal_words": []},
        )
        assert response.status_code == 200
        assert response.json()["personal_words_count"] == 0

    def test_a_single_word_is_accepted(self, client, caregiver, patient_id):
        response = client.put(
            f"/v1/patients/{patient_id}/personalization",
            headers=caregiver,
            json={"version": 1, "personal_words": [{"text": "chai"}]},
        )
        assert response.status_code == 200

    def test_a_stale_version_is_refused_rather_than_overwriting(
        self, client, caregiver, patient_id
    ):
        client.put(
            f"/v1/patients/{patient_id}/personalization",
            headers=caregiver,
            json={"version": 1, "personal_words": [{"text": "first"}]},
        )
        stale = client.put(
            f"/v1/patients/{patient_id}/personalization",
            headers=caregiver,
            json={"version": 1, "personal_words": [{"text": "second"}]},
        )
        assert stale.status_code == 409
        assert stale.json()["error"]["code"] == "revision_conflict"
        assert stale.json()["error"]["details"] == {"expected": 2, "received": 1}

        stored = client.get(
            f"/v1/patients/{patient_id}/personalization", headers=caregiver
        ).json()
        assert [w["text"] for w in stored["personal_words"]] == ["first"]


class TestActivity:
    def test_a_new_patient_gets_a_safe_default(self, client, caregiver, patient_id):
        activity = client.get(f"/v1/patients/{patient_id}/activity", headers=caregiver).json()
        assert activity["source"] == "safe_default"
        assert activity["game_id"] == "route_quest"
        assert activity["level"] == 1

    def test_content_sufficiency_is_reported_not_enforced(self, client, caregiver, patient_id):
        client.put(
            f"/v1/patients/{patient_id}/personalization",
            headers=caregiver,
            json={"version": 1, "personal_words": [{"text": "chai"}, {"text": "garden"}]},
        )
        activity = client.get(f"/v1/patients/{patient_id}/activity", headers=caregiver).json()
        sufficiency = activity["content_sufficiency"]
        assert sufficiency["personal_words"] == 2
        assert sufficiency["sufficient_for_word_games"] is False
        assert sufficiency["target_personal_words"] == "15-20"


class TestMedia:
    PNG = (
        b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"
        b"\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01"
        b"\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"
    )

    def _upload(self, client, headers, patient_id, content=None):
        return client.post(
            f"/v1/patients/{patient_id}/media",
            headers=headers,
            files={"file": ("photo.png", io.BytesIO(content or self.PNG), "image/png")},
        )

    def test_upload_and_authorized_read(self, client, caregiver, patient_id):
        uploaded = self._upload(client, caregiver, patient_id)
        assert uploaded.status_code == 201
        asset_id = uploaded.json()["media_asset_id"]

        fetched = client.get(f"/v1/media/{asset_id}", headers=caregiver)
        assert fetched.status_code == 200
        assert fetched.content == self.PNG
        # Private media must never be cached by an intermediary.
        assert fetched.headers["Cache-Control"] == "private, no-store"

    def test_another_caregiver_cannot_read_the_media(
        self, client, caregiver, other_caregiver, patient_id
    ):
        asset_id = self._upload(client, caregiver, patient_id).json()["media_asset_id"]
        assert client.get(f"/v1/media/{asset_id}", headers=other_caregiver).status_code == 403

    def test_media_requires_identity(self, client, caregiver, patient_id):
        asset_id = self._upload(client, caregiver, patient_id).json()["media_asset_id"]
        assert client.get(f"/v1/media/{asset_id}").status_code == 401

    def test_reuploading_identical_bytes_does_not_duplicate(
        self, client, caregiver, patient_id
    ):
        first = self._upload(client, caregiver, patient_id).json()
        second = self._upload(client, caregiver, patient_id).json()
        assert second["duplicate"] is True
        assert second["media_asset_id"] == first["media_asset_id"]

    def test_an_unsupported_type_is_refused(self, client, caregiver, patient_id):
        response = client.post(
            f"/v1/patients/{patient_id}/media",
            headers=caregiver,
            files={"file": ("notes.txt", io.BytesIO(b"hello"), "text/plain")},
        )
        assert response.status_code == 422
