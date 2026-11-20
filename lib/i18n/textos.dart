// Textos de la interfaz de MiSalud en inglés, alemán y francés.
// Clave = texto original en español (tal como aparece en tr('...')).
// Si falta una traducción, se muestra el español.

const Map<String, Map<String, String>> textos = {
  'Activar mi cuenta': {
    'en': 'Activate my account',
    'de': 'Mein Konto aktivieren',
    'fr': 'Activer mon compte',
  },
  'Si tu médico ya creó tu ficha en MiSalud, ingresa tu RUT y te enviaremos un link de activación a tu correo registrado.': {
    'en': 'If your doctor has already created your record in MiSalud, enter your RUT and we will send an activation link to your registered email.',
    'de': 'Wenn Ihr Arzt Ihre Akte in MiSalud bereits angelegt hat, geben Sie Ihre RUT ein und wir senden Ihnen einen Aktivierungslink an Ihre registrierte E-Mail.',
    'fr': 'Si votre médecin a déjà créé votre dossier dans MiSalud, saisissez votre RUT et nous vous enverrons un lien d\'activation à votre e-mail enregistré.',
  },
  'RUT': {
    'en': 'RUT (Chilean ID)',
    'de': 'RUT (chilenische ID)',
    'fr': 'RUT (identifiant chilien)',
  },
  'Enviar link de activación': {
    'en': 'Send activation link',
    'de': 'Aktivierungslink senden',
    'fr': 'Envoyer le lien d\'activation',
  },
  'Abre el link desde tu teléfono para confirmar tus datos y crear tu contraseña. Luego vuelve aquí e inicia sesión.': {
    'en': 'Open the link on your phone to confirm your details and create your password. Then come back here and sign in.',
    'de': 'Öffnen Sie den Link auf Ihrem Telefon, um Ihre Daten zu bestätigen und Ihr Passwort zu erstellen. Kehren Sie dann hierher zurück und melden Sie sich an.',
    'fr': 'Ouvrez le lien sur votre téléphone pour confirmer vos données et créer votre mot de passe. Revenez ensuite ici et connectez-vous.',
  },
  'Volver a iniciar sesión': {
    'en': 'Back to sign in',
    'de': 'Zurück zur Anmeldung',
    'fr': 'Retour à la connexion',
  },
  'Cancelar hora': {
    'en': 'Cancel appointment',
    'de': 'Termin absagen',
    'fr': 'Annuler le rendez-vous',
  },
  'Volver': {
    'en': 'Back',
    'de': 'Zurück',
    'fr': 'Retour',
  },
  'Cambiar hora': {
    'en': 'Change appointment',
    'de': 'Termin ändern',
    'fr': 'Modifier le rendez-vous',
  },
  'Cancelar': {
    'en': 'Cancel',
    'de': 'Abbrechen',
    'fr': 'Annuler',
  },
  'Puedes cambiarlas o cancelarlas hasta 24 horas antes.': {
    'en': 'You can change or cancel them up to 24 hours before.',
    'de': 'Sie können sie bis 24 Stunden vorher ändern oder absagen.',
    'fr': 'Vous pouvez les modifier ou les annuler jusqu\'à 24 heures avant.',
  },
  'Reintentar': {
    'en': 'Retry',
    'de': 'Erneut versuchen',
    'fr': 'Réessayer',
  },
  'No hay horas agendadas.': {
    'en': 'No appointments booked.',
    'de': 'Keine Termine vereinbart.',
    'fr': 'Aucun rendez-vous pris.',
  },
  'No hay horas libres este día.': {
    'en': 'No free slots on this day.',
    'de': 'An diesem Tag sind keine Termine frei.',
    'fr': 'Aucun créneau libre ce jour-là.',
  },
  'Cambiar': {
    'en': 'Change',
    'de': 'Ändern',
    'fr': 'Modifier',
  },
  'Iniciar consulta online': {
    'en': 'Start online consultation',
    'de': 'Online-Sprechstunde starten',
    'fr': 'Démarrer la consultation en ligne',
  },
  'Agendar': {
    'en': 'Book',
    'de': 'Buchen',
    'fr': 'Réserver',
  },
  'Autorizar acceso a médico': {
    'en': 'Authorize doctor access',
    'de': 'Arztzugriff erlauben',
    'fr': 'Autoriser l\'accès au médecin',
  },
  'Da acceso temporal a un médico para que revise esta ficha': {
    'en': 'Give a doctor temporary access to review this record',
    'de': 'Einem Arzt vorübergehend Zugriff geben, um diese Akte einzusehen',
    'fr': 'Donnez un accès temporaire à un médecin pour consulter ce dossier',
  },
  'Autorizar médico': {
    'en': 'Authorize doctor',
    'de': 'Arzt freigeben',
    'fr': 'Autoriser un médecin',
  },
  'No se pudo determinar tu RUT.': {
    'en': 'Your RUT could not be determined.',
    'de': 'Ihre RUT konnte nicht ermittelt werden.',
    'fr': 'Votre RUT n\'a pas pu être déterminé.',
  },
  '🔐 ¿Cómo funciona?': {
    'en': '🔐 How does it work?',
    'de': '🔐 Wie funktioniert das?',
    'fr': '🔐 Comment ça marche ?',
  },
  'Muestra este QR al médico': {
    'en': 'Show this QR to the doctor',
    'de': 'Zeigen Sie diesen QR-Code dem Arzt',
    'fr': 'Montrez ce QR au médecin',
  },
  'El médico escanea con la cámara de su teléfono': {
    'en': 'The doctor scans it with their phone camera',
    'de': 'Der Arzt scannt ihn mit der Handykamera',
    'fr': 'Le médecin le scanne avec l\'appareil photo de son téléphone',
  },
  '🔄 Nuevo QR': {
    'en': '🔄 New QR',
    'de': '🔄 Neuer QR-Code',
    'fr': '🔄 Nouveau QR',
  },
  'Revocar': {
    'en': 'Revoke',
    'de': 'Widerrufen',
    'fr': 'Révoquer',
  },
  'Email del médico': {
    'en': 'Doctor\'s email',
    'de': 'E-Mail des Arztes',
    'fr': 'E-mail du médecin',
  },
  'medico@ejemplo.cl': {
    'en': 'doctor@example.com',
    'de': 'arzt@beispiel.de',
    'fr': 'medecin@exemple.fr',
  },
  'Accesos activos': {
    'en': 'Active accesses',
    'de': 'Aktive Zugriffe',
    'fr': 'Accès actifs',
  },
  'Historial': {
    'en': 'History',
    'de': 'Verlauf',
    'fr': 'Historique',
  },
  'Revocar acceso': {
    'en': 'Revoke access',
    'de': 'Zugriff widerrufen',
    'fr': 'Révoquer l\'accès',
  },
  'Consulta sin conexión': {
    'en': 'Offline consultation',
    'de': 'Sprechstunde ohne Verbindung',
    'fr': 'Consultation hors ligne',
  },
  'Compartir la ficha sin internet': {
    'en': 'Share the record without internet',
    'de': 'Akte ohne Internet teilen',
    'fr': 'Partager le dossier sans internet',
  },
  'Acepto': {
    'en': 'I agree',
    'de': 'Ich stimme zu',
    'fr': 'J\'accepte',
  },
  'Confirmar con huella y comenzar': {
    'en': 'Confirm with fingerprint and start',
    'de': 'Mit Fingerabdruck bestätigen und starten',
    'fr': 'Confirmer avec l\'empreinte et commencer',
  },
  'El teléfono crea una red Wi-Fi propia (no da internet). El profesional se conecta, abre la ficha en su navegador y escribe su nota. No se descarga ningún archivo a su equipo. Dura 30 minutos o hasta que toques "Terminar".': {
    'en': 'The phone creates its own Wi-Fi network (no internet). The professional connects, opens the record in their browser and writes their note. No file is downloaded to their computer. It lasts 30 minutes or until you tap "Finish".',
    'de': 'Das Telefon erstellt ein eigenes WLAN (ohne Internet). Die Fachperson verbindet sich, öffnet die Akte im Browser und schreibt ihre Notiz. Es wird keine Datei auf ihr Gerät heruntergeladen. Es dauert 30 Minuten oder bis Sie auf "Beenden" tippen.',
    'fr': 'Le téléphone crée son propre réseau Wi-Fi (sans internet). Le professionnel se connecte, ouvre le dossier dans son navigateur et rédige sa note. Aucun fichier n\'est téléchargé sur son ordinateur. Cela dure 30 minutes ou jusqu\'à ce que vous touchiez "Terminer".',
  },
  'Paso 1 de 2 · Conectar el computador a este teléfono': {
    'en': 'Step 1 of 2 · Connect the computer to this phone',
    'de': 'Schritt 1 von 2 · Computer mit diesem Telefon verbinden',
    'fr': 'Étape 1 sur 2 · Connecter l\'ordinateur à ce téléphone',
  },
  'Conectado · Siguiente': {
    'en': 'Connected · Next',
    'de': 'Verbunden · Weiter',
    'fr': 'Connecté · Suivant',
  },
  'El computador debe estar en la misma red Wi-Fi que este teléfono.': {
    'en': 'The computer must be on the same Wi-Fi network as this phone.',
    'de': 'Der Computer muss im selben WLAN wie dieses Telefon sein.',
    'fr': 'L\'ordinateur doit être sur le même réseau Wi-Fi que ce téléphone.',
  },
  'Volver al paso 1': {
    'en': 'Back to step 1',
    'de': 'Zurück zu Schritt 1',
    'fr': 'Retour à l\'étape 1',
  },
  'Terminar': {
    'en': 'Finish',
    'de': 'Beenden',
    'fr': 'Terminer',
  },
  'Cotizando en farmacias, un momento...': {
    'en': 'Checking pharmacy prices, one moment...',
    'de': 'Apothekenpreise werden abgefragt, einen Moment...',
    'fr': 'Comparaison des prix en pharmacie, un instant...',
  },
  'No hay farmacias disponibles.': {
    'en': 'No pharmacies available.',
    'de': 'Keine Apotheken verfügbar.',
    'fr': 'Aucune pharmacie disponible.',
  },
  'Precios referenciales, sujetos a cambio en cada farmacia.': {
    'en': 'Reference prices, subject to change at each pharmacy.',
    'de': 'Richtpreise, können je nach Apotheke abweichen.',
    'fr': 'Prix indicatifs, susceptibles de changer selon la pharmacie.',
  },
  'Total': {
    'en': 'Total',
    'de': 'Gesamt',
    'fr': 'Total',
  },
  '💊 Cotizador de medicamentos': {
    'en': '💊 Medicine price checker',
    'de': '💊 Medikamenten-Preisvergleich',
    'fr': '💊 Comparateur de prix des médicaments',
  },
  'Compara precios de tus recetas entre farmacias': {
    'en': 'Compare your prescription prices across pharmacies',
    'de': 'Vergleichen Sie die Preise Ihrer Rezepte zwischen Apotheken',
    'fr': 'Comparez les prix de vos ordonnances entre pharmacies',
  },
  'Cuidadores': {
    'en': 'Caregivers',
    'de': 'Betreuungspersonen',
    'fr': 'Aidants',
  },
  'Agregar cuidador': {
    'en': 'Add caregiver',
    'de': 'Betreuungsperson hinzufügen',
    'fr': 'Ajouter un aidant',
  },
  'Aún no has invitado a ningún cuidador': {
    'en': 'You haven\'t invited any caregiver yet',
    'de': 'Sie haben noch keine Betreuungsperson eingeladen',
    'fr': 'Vous n\'avez encore invité aucun aidant',
  },
  'Quitar': {
    'en': 'Remove',
    'de': 'Entfernen',
    'fr': 'Retirer',
  },
  'Código generado': {
    'en': 'Code generated',
    'de': 'Code erstellt',
    'fr': 'Code généré',
  },
  '✓ Invitación enviada. Tu cuidador debe aceptarla desde su cuenta, en "Cuidadores → Yo cuido". Si está contigo, también puede escanear este código. Vence el ': {
    'en': '✓ Invitation sent. Your caregiver must accept it from their account, under "Cuidadores → Yo cuido". If they are with you, they can also scan this code. Expires on ',
    'de': '✓ Einladung gesendet. Ihre Betreuungsperson muss sie in ihrem Konto unter "Cuidadores → Yo cuido" annehmen. Wenn sie bei Ihnen ist, kann sie auch diesen Code scannen. Gültig bis ',
    'fr': '✓ Invitation envoyée. Votre aidant doit l\'accepter depuis son compte, dans "Cuidadores → Yo cuido". S\'il est avec vous, il peut aussi scanner ce code. Expire le ',
  },
  'Listo': {
    'en': 'Done',
    'de': 'Fertig',
    'fr': 'Terminé',
  },
  'Invitar a un cuidador': {
    'en': 'Invite a caregiver',
    'de': 'Betreuungsperson einladen',
    'fr': 'Inviter un aidant',
  },
  'Nombre': {
    'en': 'First name',
    'de': 'Vorname',
    'fr': 'Prénom',
  },
  'Apellidos': {
    'en': 'Last name',
    'de': 'Nachname',
    'fr': 'Nom',
  },
  'RUT del cuidador': {
    'en': 'Caregiver\'s RUT',
    'de': 'RUT der Betreuungsperson',
    'fr': 'RUT de l\'aidant',
  },
  'Relación (opcional)': {
    'en': 'Relationship (optional)',
    'de': 'Beziehung (optional)',
    'fr': 'Relation (facultatif)',
  },
  'Hijo, esposa, cuidador...': {
    'en': 'Son, wife, caregiver...',
    'de': 'Sohn, Ehefrau, Betreuer...',
    'fr': 'Fils, épouse, aidant...',
  },
  'Generar código QR': {
    'en': 'Generate QR code',
    'de': 'QR-Code erstellen',
    'fr': 'Générer un code QR',
  },
  'Rechazar': {
    'en': 'Decline',
    'de': 'Ablehnen',
    'fr': 'Refuser',
  },
  'Aceptar': {
    'en': 'Accept',
    'de': 'Annehmen',
    'fr': 'Accepter',
  },
  '✓ Aceptar': {
    'en': '✓ Accept',
    'de': '✓ Annehmen',
    'fr': '✓ Accepter',
  },
  'Escanear código': {
    'en': 'Scan code',
    'de': 'Code scannen',
    'fr': 'Scanner le code',
  },
  'No cuidas a nadie todavía.\nCuando alguien te invite, la invitación aparecerá aquí.': {
    'en': 'You don\'t care for anyone yet.\nWhen someone invites you, the invitation will appear here.',
    'de': 'Sie betreuen noch niemanden.\nWenn Sie jemand einlädt, erscheint die Einladung hier.',
    'fr': 'Vous ne vous occupez encore de personne.\nQuand quelqu\'un vous invitera, l\'invitation apparaîtra ici.',
  },
  'Apunta al código QR del paciente': {
    'en': 'Point at the patient\'s QR code',
    'de': 'Auf den QR-Code des Patienten richten',
    'fr': 'Visez le code QR du patient',
  },
  'La huella está activa': {
    'en': 'Fingerprint is on',
    'de': 'Fingerabdruck ist aktiv',
    'fr': 'L\'empreinte est activée',
  },
  'Entras con tu huella y te la pedimos si no usas la app por 5 minutos. ¿Quieres desactivarla? Volverás a entrar con tu contraseña.': {
    'en': 'You sign in with your fingerprint, and we ask for it if you don\'t use the app for 5 minutes. Do you want to turn it off? You will sign in with your password again.',
    'de': 'Sie melden sich mit Fingerabdruck an; wir fragen ihn ab, wenn Sie die App 5 Minuten nicht nutzen. Möchten Sie ihn deaktivieren? Sie melden sich dann wieder mit Passwort an.',
    'fr': 'Vous vous connectez avec votre empreinte, et nous la demandons si vous n\'utilisez pas l\'application pendant 5 minutes. Voulez-vous la désactiver ? Vous vous reconnecterez avec votre mot de passe.',
  },
  'Desactivar': {
    'en': 'Turn off',
    'de': 'Deaktivieren',
    'fr': 'Désactiver',
  },
  '¿Entrar con tu huella?': {
    'en': 'Sign in with your fingerprint?',
    'de': 'Mit Fingerabdruck anmelden?',
    'fr': 'Se connecter avec votre empreinte ?',
  },
  'Entra con tu huella (o el PIN de tu teléfono) sin escribir la contraseña. Si no usas la app por 5 minutos, te la pediremos para proteger tu ficha.': {
    'en': 'Sign in with your fingerprint (or your phone PIN) without typing the password. If you don\'t use the app for 5 minutes, we\'ll ask for it to protect your record.',
    'de': 'Melden Sie sich mit Fingerabdruck (oder der PIN Ihres Telefons) an, ohne das Passwort einzugeben. Wenn Sie die App 5 Minuten nicht nutzen, fragen wir ihn zum Schutz Ihrer Akte ab.',
    'fr': 'Connectez-vous avec votre empreinte (ou le code PIN de votre téléphone) sans saisir le mot de passe. Si vous n\'utilisez pas l\'application pendant 5 minutes, nous la demanderons pour protéger votre dossier.',
  },
  'Ahora no': {
    'en': 'Not now',
    'de': 'Jetzt nicht',
    'fr': 'Pas maintenant',
  },
  'Activar': {
    'en': 'Turn on',
    'de': 'Aktivieren',
    'fr': 'Activer',
  },
  'Confirma tu contraseña': {
    'en': 'Confirm your password',
    'de': 'Passwort bestätigen',
    'fr': 'Confirmez votre mot de passe',
  },
  'Contraseña de MiSalud': {
    'en': 'MiSalud password',
    'de': 'MiSalud-Passwort',
    'fr': 'Mot de passe MiSalud',
  },
  'Confirmar': {
    'en': 'Confirm',
    'de': 'Bestätigen',
    'fr': 'Confirmer',
  },
  'Entendido': {
    'en': 'Got it',
    'de': 'Verstanden',
    'fr': 'Compris',
  },
  'Cerrar sesión': {
    'en': 'Sign out',
    'de': 'Abmelden',
    'fr': 'Se déconnecter',
  },
  'Política de privacidad': {
    'en': 'Privacy policy',
    'de': 'Datenschutzerklärung',
    'fr': 'Politique de confidentialité',
  },
  'Eliminar mi cuenta': {
    'en': 'Delete my account',
    'de': 'Mein Konto löschen',
    'fr': 'Supprimer mon compte',
  },
  'Olvidar este teléfono': {
    'en': 'Forget this phone',
    'de': 'Dieses Telefon vergessen',
    'fr': 'Oublier ce téléphone',
  },
  'Salir': {
    'en': 'Exit',
    'de': 'Beenden',
    'fr': 'Quitter',
  },
  'Se borran tu acceso, tus recordatorios, tus cuidadores y las personas que cuidas.\n\nTu ficha clínica no se borra: la conserva tu centro de salud porque la ley lo exige. Si vuelves a activar tu cuenta podrás verla de nuevo.': {
    'en': 'Your access, reminders, caregivers and the people you care for will be deleted.\n\nYour medical record is not deleted: your health center keeps it because the law requires it. If you activate your account again you will be able to see it.',
    'de': 'Ihr Zugang, Ihre Erinnerungen, Ihre Betreuungspersonen und die Personen, die Sie betreuen, werden gelöscht.\n\nIhre Krankenakte wird nicht gelöscht: Ihr Gesundheitszentrum bewahrt sie auf, weil das Gesetz es verlangt. Wenn Sie Ihr Konto erneut aktivieren, können Sie sie wieder sehen.',
    'fr': 'Votre accès, vos rappels, vos aidants et les personnes dont vous vous occupez seront supprimés.\n\nVotre dossier médical n\'est pas supprimé : votre centre de santé le conserve car la loi l\'exige. Si vous réactivez votre compte, vous pourrez le revoir.',
  },
  'Confirma con tu contraseña': {
    'en': 'Confirm with your password',
    'de': 'Mit Passwort bestätigen',
    'fr': 'Confirmez avec votre mot de passe',
  },
  'Entiendo que no se puede deshacer': {
    'en': 'I understand this cannot be undone',
    'de': 'Ich verstehe, dass dies nicht rückgängig gemacht werden kann',
    'fr': 'Je comprends que c\'est irréversible',
  },
  'Eliminar': {
    'en': 'Delete',
    'de': 'Löschen',
    'fr': 'Supprimer',
  },
  'HypokratIA': {
    'en': 'HypokratIA',
    'de': 'HypokratIA',
    'fr': 'HypokratIA',
  },
  'Ingreso con huella': {
    'en': 'Fingerprint sign-in',
    'de': 'Anmeldung mit Fingerabdruck',
    'fr': 'Connexion par empreinte',
  },
  'No se pudieron actualizar las alarmas': {
    'en': 'The alarms could not be updated',
    'de': 'Die Wecker konnten nicht aktualisiert werden',
    'fr': 'Les alarmes n\'ont pas pu être mises à jour',
  },
  'Esto necesita conexión': {
    'en': 'This needs a connection',
    'de': 'Dafür ist eine Verbindung nötig',
    'fr': 'Cela nécessite une connexion',
  },
  'Entrar con huella': {
    'en': 'Sign in with fingerprint',
    'de': 'Mit Fingerabdruck anmelden',
    'fr': 'Se connecter avec l\'empreinte',
  },
  'Usar mi contraseña': {
    'en': 'Use my password',
    'de': 'Mein Passwort verwenden',
    'fr': 'Utiliser mon mot de passe',
  },
  'Mi dirección': {
    'en': 'My address',
    'de': 'Meine Adresse',
    'fr': 'Mon adresse',
  },
  'Donde te atienden a domicilio. Escribe calle, número y elige la comuna; después confírmala en el mapa.': {
    'en': 'Where you receive home visits. Type the street and number and choose the district; then confirm it on the map.',
    'de': 'Wo Sie Hausbesuche erhalten. Geben Sie Straße und Hausnummer ein und wählen Sie die Gemeinde; bestätigen Sie sie dann auf der Karte.',
    'fr': 'Où vous recevez les visites à domicile. Saisissez la rue et le numéro et choisissez la commune ; puis confirmez-la sur la carte.',
  },
  '¿El punto está en el lugar correcto?': {
    'en': 'Is the pin in the right place?',
    'de': 'Ist die Markierung am richtigen Ort?',
    'fr': 'Le repère est-il au bon endroit ?',
  },
  'No, corregir': {
    'en': 'No, fix it',
    'de': 'Nein, korrigieren',
    'fr': 'Non, corriger',
  },
  'Explícame esta consulta en simple': {
    'en': 'Explain this consultation in simple terms',
    'de': 'Erkläre mir diese Sprechstunde einfach',
    'fr': 'Explique-moi cette consultation simplement',
  },
  'Esta consulta no tiene detalle adicional registrado': {
    'en': 'This consultation has no additional details recorded',
    'de': 'Zu dieser Sprechstunde sind keine weiteren Details erfasst',
    'fr': 'Cette consultation n\'a pas de détails supplémentaires enregistrés',
  },
  'PDF': {
    'en': 'PDF',
    'de': 'PDF',
    'fr': 'PDF',
  },
  'Cerrar foto': {
    'en': 'Close photo',
    'de': 'Foto schließen',
    'fr': 'Fermer la photo',
  },
  'Esta consulta, en simple': {
    'en': 'This consultation, in simple terms',
    'de': 'Diese Sprechstunde, einfach erklärt',
    'fr': 'Cette consultation, en termes simples',
  },
  'Ficha del paciente': {
    'en': 'Patient record',
    'de': 'Patientenakte',
    'fr': 'Dossier du patient',
  },
  '¿Cómo te sientes hoy?': {
    'en': 'How do you feel today?',
    'de': 'Wie fühlen Sie sich heute?',
    'fr': 'Comment vous sentez-vous aujourd\'hui ?',
  },
  'Información médica importante': {
    'en': 'Important medical information',
    'de': 'Wichtige medizinische Informationen',
    'fr': 'Informations médicales importantes',
  },
  'Ver todos mis antecedentes →': {
    'en': 'See all my medical history →',
    'de': 'Gesamte Vorgeschichte ansehen →',
    'fr': 'Voir tous mes antécédents →',
  },
  'Mi ficha clínica': {
    'en': 'My medical record',
    'de': 'Meine Krankenakte',
    'fr': 'Mon dossier médical',
  },
  'Explícame mi historial en simple': {
    'en': 'Explain my history in simple terms',
    'de': 'Erkläre mir meine Krankengeschichte einfach',
    'fr': 'Explique-moi mon historique simplement',
  },
  'Aún no tienes consultas registradas': {
    'en': 'You have no consultations recorded yet',
    'de': 'Sie haben noch keine erfassten Sprechstunden',
    'fr': 'Vous n\'avez encore aucune consultation enregistrée',
  },
  'Mis antecedentes': {
    'en': 'My medical history',
    'de': 'Meine Vorgeschichte',
    'fr': 'Mes antécédents',
  },
  'Acceso autorizado: indicaciones': {
    'en': 'Authorized access: instructions',
    'de': 'Freigegebener Zugriff: Anweisungen',
    'fr': 'Accès autorisé : prescriptions',
  },
  'Acceso autorizado: completo': {
    'en': 'Authorized access: full',
    'de': 'Freigegebener Zugriff: vollständig',
    'fr': 'Accès autorisé : complet',
  },
  'Antecedentes médicos': {
    'en': 'Medical history',
    'de': 'Medizinische Vorgeschichte',
    'fr': 'Antécédents médicaux',
  },
  'Nivel de acceso no reconocido': {
    'en': 'Unrecognized access level',
    'de': 'Unbekannte Zugriffsstufe',
    'fr': 'Niveau d\'accès non reconnu',
  },
  'Historial de consultas': {
    'en': 'Consultation history',
    'de': 'Verlauf der Sprechstunden',
    'fr': 'Historique des consultations',
  },
  'Sin consultas registradas': {
    'en': 'No consultations recorded',
    'de': 'Keine Sprechstunden erfasst',
    'fr': 'Aucune consultation enregistrée',
  },
  '✨ Explicar': {
    'en': '✨ Explain',
    'de': '✨ Erklären',
    'fr': '✨ Expliquer',
  },
  'Confirmar con huella y buscar': {
    'en': 'Confirm with fingerprint and search',
    'de': 'Mit Fingerabdruck bestätigen und suchen',
    'fr': 'Confirmer avec l\'empreinte et rechercher',
  },
  'Mantén el teléfono cerca del computador, con el Bluetooth encendido.': {
    'en': 'Keep the phone near the computer, with Bluetooth on.',
    'de': 'Halten Sie das Telefon mit eingeschaltetem Bluetooth in der Nähe des Computers.',
    'fr': 'Gardez le téléphone près de l\'ordinateur, avec le Bluetooth activé.',
  },
  'Verifica que el programa Lector HypokratIA esté abierto en el computador y que el Bluetooth del teléfono esté encendido.': {
    'en': 'Check that the HypokratIA Reader program is open on the computer and that the phone\'s Bluetooth is on.',
    'de': 'Prüfen Sie, ob das Programm HypokratIA Reader auf dem Computer geöffnet und Bluetooth am Telefon eingeschaltet ist.',
    'fr': 'Vérifiez que le programme Lecteur HypokratIA est ouvert sur l\'ordinateur et que le Bluetooth du téléphone est activé.',
  },
  'Intentar de nuevo': {
    'en': 'Try again',
    'de': 'Erneut versuchen',
    'fr': 'Réessayer',
  },
  'Usar la red del teléfono (QR)': {
    'en': 'Use the phone\'s network (QR)',
    'de': 'Netzwerk des Telefons verwenden (QR)',
    'fr': 'Utiliser le réseau du téléphone (QR)',
  },
  'El computador del médico debe mostrar este mismo código:': {
    'en': 'The doctor\'s computer must show this same code:',
    'de': 'Der Computer des Arztes muss denselben Code anzeigen:',
    'fr': 'L\'ordinateur du médecin doit afficher ce même code :',
  },
  'Esperando que el médico toque ACEPTAR…': {
    'en': 'Waiting for the doctor to accept…',
    'de': 'Warten, bis der Arzt annimmt…',
    'fr': 'En attente de l\'acceptation du médecin…',
  },
  'Revisa tu correo': {
    'en': 'Check your email',
    'de': 'Prüfen Sie Ihre E-Mails',
    'fr': 'Vérifiez vos e-mails',
  },
  'Estás entrando desde un teléfono nuevo. Te enviamos un código de 6 dígitos a ': {
    'en': 'You are signing in from a new phone. We sent a 6-digit code to ',
    'de': 'Sie melden sich von einem neuen Telefon an. Wir haben einen 6-stelligen Code gesendet an ',
    'fr': 'Vous vous connectez depuis un nouveau téléphone. Nous avons envoyé un code à 6 chiffres à ',
  },
  'tu correo': {
    'en': 'your email',
    'de': 'Ihre E-Mail',
    'fr': 'votre e-mail',
  },
  '. Vale 10 minutos.': {
    'en': '. It is valid for 10 minutes.',
    'de': '. Er ist 10 Minuten gültig.',
    'fr': '. Il est valable 10 minutes.',
  },
  'Entrar': {
    'en': 'Sign in',
    'de': 'Anmelden',
    'fr': 'Se connecter',
  },
  'No me llegó: volver a intentar': {
    'en': 'I didn\'t get it: try again',
    'de': 'Nicht erhalten: erneut versuchen',
    'fr': 'Je ne l\'ai pas reçu : réessayer',
  },
  'Revisa también la carpeta de spam. Este teléfono quedará como de confianza.': {
    'en': 'Also check your spam folder. This phone will be marked as trusted.',
    'de': 'Prüfen Sie auch den Spam-Ordner. Dieses Telefon wird als vertrauenswürdig gespeichert.',
    'fr': 'Vérifiez aussi le dossier spam. Ce téléphone sera enregistré comme appareil de confiance.',
  },
  'Software Médico': {
    'en': 'Medical Software',
    'de': 'Medizinische Software',
    'fr': 'Logiciel médical',
  },
  'Ingresa a tu cuenta': {
    'en': 'Sign in to your account',
    'de': 'Melden Sie sich bei Ihrem Konto an',
    'fr': 'Connectez-vous à votre compte',
  },
  'Contraseña': {
    'en': 'Password',
    'de': 'Passwort',
    'fr': 'Mot de passe',
  },
  'Ingresar': {
    'en': 'Sign in',
    'de': 'Anmelden',
    'fr': 'Se connecter',
  },
  '¿Primera vez? Activa tu cuenta': {
    'en': 'First time? Activate your account',
    'de': 'Zum ersten Mal hier? Konto aktivieren',
    'fr': 'Première fois ? Activez votre compte',
  },
  'Tu ejercicio': {
    'en': 'Your exercise',
    'de': 'Ihre Übung',
    'fr': 'Votre exercice',
  },
  '¡YA!': {
    'en': 'NOW!',
    'de': 'JETZT!',
    'fr': 'MAINTENANT !',
  },
  'Leí y acepto los Términos de uso.': {
    'en': 'I have read and accept the Terms of use.',
    'de': 'Ich habe die Nutzungsbedingungen gelesen und akzeptiere sie.',
    'fr': 'J\'ai lu et j\'accepte les Conditions d\'utilisation.',
  },
  'Tú': {
    'en': 'You',
    'de': 'Sie',
    'fr': 'Vous',
  },
  'Código para el profesional': {
    'en': 'Code for the professional',
    'de': 'Code für die Fachperson',
    'fr': 'Code pour le professionnel',
  },
  'Entrégaselo cuando llegue': {
    'en': 'Give it to them when they arrive',
    'de': 'Geben Sie ihn bei Ankunft weiter',
    'fr': 'Donnez-le-lui à son arrivée',
  },
  'Ver en el mapa': {
    'en': 'See on the map',
    'de': 'Auf der Karte ansehen',
    'fr': 'Voir sur la carte',
  },
  'Actualizar': {
    'en': 'Refresh',
    'de': 'Aktualisieren',
    'fr': 'Actualiser',
  },
  '💵 Pago en efectivo al profesional': {
    'en': '💵 Cash payment to the professional',
    'de': '💵 Barzahlung an die Fachperson',
    'fr': '💵 Paiement en espèces au professionnel',
  },
  '🗓 Convenio mensual': {
    'en': '🗓 Monthly plan',
    'de': '🗓 Monatsvertrag',
    'fr': '🗓 Forfait mensuel',
  },
  'Ficha': {
    'en': 'Record',
    'de': 'Akte',
    'fr': 'Dossier',
  },
  'Recordatorios': {
    'en': 'Reminders',
    'de': 'Erinnerungen',
    'fr': 'Rappels',
  },
  'Agenda': {
    'en': 'Appointments',
    'de': 'Termine',
    'fr': 'Rendez-vous',
  },
  'Cotizador': {
    'en': 'Prices',
    'de': 'Preise',
    'fr': 'Prix',
  },
  'Autorizar': {
    'en': 'Authorize',
    'de': 'Freigeben',
    'fr': 'Autoriser',
  },
};
