// Get firebase
const firebase = require("@firebase/rules-unit-testing");
// Get firebase test helpers
const { assertFails, assertSucceeds } = require("@firebase/rules-unit-testing");

// Preset test data

const MY_PROJECT_ID = "itsuda50"; // real firebase project id.
const myUid = "myUid";
const otherUid = "otherUid";
const myAuth = { uid: myUid, email: "my-email@gmail.com" };
const otherAuth = { uid: otherUid, email: "other-email@gmail.com" };

//
const roomId = "room-id-123";

const adminDb = firebase
  .initializeAdminApp({ projectId: MY_PROJECT_ID })
  .firestore();

// Helper function to make the test code simple.
const setup = async (auth, data) => {
  // Initialize Firestore instance with user auth login.
  db = firebase
    .initializeTestApp({ projectId: MY_PROJECT_ID, auth: auth })
    .firestore();

  // Push default data to Firestore
  // If there is data to set, set it with admin instance.
  if (data && Object.keys(data).length > 0) {
    for (const key in data) {
      // key 마다, 데이터를 모두 기록한다.
      // Save data for each path.
      const ref = adminDb.doc(key);
      await ref.set(data[key]);
    }
  }
  return db;
};

const globalRoomListPath = `chat/global-rooms/list/`;
const globalRoomList = function (db) {
  return db.collection("chat").doc("global-rooms").collection("list");
};
const myRoomList = function (db) {
  return db.collection("chat").doc("user-rooms");
};

describe("Chat", () => {
  it("Create a room", async () => {
    // Clear database before you are creating a room(Or it may not work on re-creating.)
    await firebase.clearFirestoreData({ projectId: MY_PROJECT_ID });

    const db = await setup(myAuth, null);
    const globalRoomRef = globalRoomList(db).doc(roomId);
    await assertSucceeds(globalRoomRef.set({ users: [myAuth.uid] }));
  });

  it("Update other room info: replace users: [otherUid] to users: [myUid]", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: { users: [otherUid] }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);
    await assertFails(roomInfoDoc.update({ users: [myAuth.uid] }));
  });

  it("Update other room info: add property val: 1", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: { users: [otherUid] }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);
    await assertFails(roomInfoDoc.update({ val: 1 }));
  });

  it("Update room info: Can't update any property", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: { users: [myUid], val: 0 }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);
    await assertFails(roomInfoDoc.update({ val: 1 }));
  });

  it("Read other room with empty user", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: { users: [] }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);
    await assertFails(roomInfoDoc.get());
  });

  it("Read other message from room (not my room)", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: { users: [otherUid] }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);
    await assertFails(roomInfoDoc.get());
  });

  it("Read room info of my room", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: { users: [myUid] }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);
    await assertSucceeds(roomInfoDoc.get());
  });

  it("Add otherUid to my room where I am alone", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: {
        users: [myUid],
        blockedUsers: null
      }
    });
    const globalRoomRef = globalRoomList(db).doc(roomId);
    await assertSucceeds(globalRoomRef.update({ users: [myUid, otherUid] }));
  });

  it("Add a user to my room", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: { users: [myAuth.uid, otherUid] }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);
    await assertSucceeds(
      roomInfoDoc.update({ users: [myAuth.uid, otherUid, "adding-a-user"] })
    );
  });

  it("Add two users to my room", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: { users: [myAuth.uid, otherUid] }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);
    await assertSucceeds(
      roomInfoDoc.update({
        users: [myAuth.uid, otherUid, "adding-user-1", "adding-user-2"]
      })
    );
  });

  it("Adding many users and one of them is in block list and must fail", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: {
        users: [myAuth.uid, otherUid],
        blockedUsers: ["blocked-A"]
      }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);
    await assertFails(
      roomInfoDoc.update({
        users: [myAuth.uid, otherUid, "user-1", "user-2", "blocked-A"]
      })
    );
  });

  it("Adding many users and two of them are in block list and must fail", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: {
        users: [myAuth.uid, otherUid],
        blockedUsers: ["blocked-A", "blocked-B", "blocked-C", "blocked-D"]
      }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);
    await assertFails(
      roomInfoDoc.update({
        users: [
          myAuth.uid,
          otherUid,
          "blocked-B",
          "blocked-D",
          "user-1",
          "user-2"
        ]
      })
    );
  });

  it("Moderator cannot add users who are in block list", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: {
        moderators: [myUid],
        users: [myAuth.uid, otherUid],
        blockedUsers: ["blocked-A", "blocked-B", "blocked-C", "blocked-D"]
      }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);
    await assertFails(
      roomInfoDoc.update({
        users: [
          myAuth.uid,
          otherUid,
          "blocked-B",
          "blocked-D",
          "user-1",
          "user-2"
        ]
      })
    );
  });

  it("Removing other user by a user shoud be failed: ", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: { users: [myAuth.uid, otherUid] }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);

    /// Remove otherUid
    await assertFails(
      roomInfoDoc.update({ users: [myAuth.uid, "user-1", "user-2"] })
    );
  });

  it("Removing a user by a user shoud be failed (2): ", async () => {
    const db = await setup(otherAuth, {
      [`${globalRoomListPath}${roomId}`]: {
        users: [myAuth.uid, otherUid, "your-uid"]
      }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);

    /// Remove 'your-uid'
    await assertFails(roomInfoDoc.update({ users: [myAuth.uid] }));
  });

  it("Removing a user by a moderator shoud be success: ", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: {
        moderators: [myUid, "his-uid"],
        users: [myAuth.uid, otherUid, "your-uid"]
      }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);
    await assertSucceeds(roomInfoDoc.update({ users: [myAuth.uid] }));
  });

  it("Read room(last message) from my room list", async () => {
    const db = await setup(myAuth, {
      [`chat/my-room-list/${myUid}/${roomId}`]: {
        users: [myUid, otherUid, "your-uid"]
      }
    });
    const roomInfoDoc = myRoomList(db).collection(myUid).doc(roomId);
    await assertSucceeds(roomInfoDoc.get());
  });

  it("Can't read room in other room list", async () => {
    const db = await setup(myAuth, {
      [`chat/my-room-list/${otherUid}/${roomId}`]: {
        users: [myUid, otherUid, "your-uid"]
      }
    });
    const roomInfoDoc = myRoomList(db).collection(otherUid).doc(roomId);
    await assertFails(roomInfoDoc.get());
  });

  it("Delete room of other user's room list", async () => {
    const db = await setup(myAuth, {
      [`chat/my-room-list/${otherUid}/${roomId}`]: {
        users: [myUid, otherUid, "your-uid"]
      }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);
    await assertFails(roomInfoDoc.delete());
  });

  it("Can't delete room(last message) from other user's room list", async () => {
    const db = await setup(myAuth, {
      [`chat/my-room-list/${otherUid}/${roomId}`]: {
        users: [myUid, otherUid, "your-uid"]
      }
    });
    const roomInfoDoc = myRoomList(db).collection(otherUid).doc(roomId);
    await assertFails(roomInfoDoc.delete());
  });

  it("Leave from room", async () => {
    const db = await setup(myAuth, {
      [`${globalRoomListPath}${roomId}`]: {
        users: [myUid, otherUid, "your-uid"]
      }
    });
    const roomInfoDoc = globalRoomList(db).doc(roomId);

    /// Remove myUid. Leaving room.
    await assertSucceeds(roomInfoDoc.update({ users: [otherUid, "your-uid"] }));
  });

  it("Delete room(last message) from my room list", async () => {
    const db = await setup(myAuth, {
      [`chat/my-room-list/${myUid}/${roomId}`]: {
        users: [myUid, otherUid, "your-uid"]
      }
    });
    const roomInfoDoc = myRoomList(db).collection(myUid).doc(roomId);
    await assertSucceeds(roomInfoDoc.delete());
  });
});
