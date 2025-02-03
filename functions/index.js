const {logger} = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.deleteExpiredColetas = require("firebase-functions/v1")
    .pubsub.schedule("every 5 minutes")
    .onRun(async (context) => {
      const firestore = admin.firestore();
      const now = admin.firestore.Timestamp.now();
      const expirationTime = 15 * 60 * 1000;
      const coletasRef = firestore.collection("coletas");

      try {
        const snapshot = await coletasRef.where("createdAt", "<", now).get();

        const batch = firestore.batch();

        for (const doc of snapshot.docs) {
          const createdAt = doc.data().createdAt.toMillis();
          const coletaId = doc.id;

          if (now.toMillis() - createdAt >= expirationTime) {
            const propostasSnapshot = await firestore
                .collection("coletas")
                .doc(coletaId)
                .collection("propostas")
                .get();

            if (propostasSnapshot.empty) {
              batch.delete(doc.ref);
              logger.info(`Coleta ${coletaId} deletada.`);
            } else {
              logger.info(`Coleta ${coletaId} mantida.`);
            }
          }
        }

        await batch.commit();
        logger.info("Processamento concluído.");
      } catch (error) {
        logger.error("Erro ao processar:", error);
      }
    });
