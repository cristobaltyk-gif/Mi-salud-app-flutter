// Textos de la interfaz de MiSalud en inglés, alemán y francés.
// Clave = texto original en español (tal como aparece en tr('...') o trp('...')).
// {0}, {1}… son los datos que se insertan (nombres, fechas, cantidades).
// Si falta una traducción, se muestra el español.
// GENERADO desde herramientas/i18n/traducciones.py.

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
  'Ocurrió un error al mostrar esta pantalla:\n\n{0}': {
    'en': 'An error occurred while showing this screen:\n\n{0}',
    'de': 'Beim Anzeigen dieses Bildschirms ist ein Fehler aufgetreten:\n\n{0}',
    'fr': 'Une erreur s\'est produite lors de l\'affichage de cet écran :\n\n{0}',
  },
  'Tu sesión expiró. Vuelve a ingresar con tu contraseña.': {
    'en': 'Your session expired. Sign in again with your password.',
    'de': 'Ihre Sitzung ist abgelaufen. Melden Sie sich erneut mit Ihrem Passwort an.',
    'fr': 'Votre session a expiré. Reconnectez-vous avec votre mot de passe.',
  },
  'Esperando médico': {
    'en': 'Waiting for doctor',
    'de': 'Warten auf Arzt',
    'fr': 'En attente du médecin',
  },
  'En uso ahora': {
    'en': 'In use now',
    'de': 'Gerade in Nutzung',
    'fr': 'En cours d\'utilisation',
  },
  'Sesión cerrada': {
    'en': 'Session closed',
    'de': 'Sitzung beendet',
    'fr': 'Session fermée',
  },
  'Expirado': {
    'en': 'Expired',
    'de': 'Abgelaufen',
    'fr': 'Expiré',
  },
  'Revocado': {
    'en': 'Revoked',
    'de': 'Widerrufen',
    'fr': 'Révoqué',
  },
  'Desconocido': {
    'en': 'Unknown',
    'de': 'Unbekannt',
    'fr': 'Inconnu',
  },
  'Pieza {0}: {1}': {
    'en': 'Tooth {0}: {1}',
    'de': 'Zahn {0}: {1}',
    'fr': 'Dent {0} : {1}',
  },
  'Ingresa tu RUT': {
    'en': 'Enter your RUT',
    'de': 'Geben Sie Ihre RUT ein',
    'fr': 'Saisissez votre RUT',
  },
  'No se pudo conectar. Revisa tu conexión a internet.': {
    'en': 'Could not connect. Check your internet connection.',
    'de': 'Verbindung fehlgeschlagen. Prüfen Sie Ihre Internetverbindung.',
    'fr': 'Connexion impossible. Vérifiez votre connexion internet.',
  },
  'Revisa tu correo para continuar.': {
    'en': 'Check your email to continue.',
    'de': 'Prüfen Sie Ihre E-Mails, um fortzufahren.',
    'fr': 'Vérifiez vos e-mails pour continuer.',
  },
  '¿Cancelar la hora del {0} a las {1} con {2}?': {
    'en': 'Cancel the appointment on {0} at {1} with {2}?',
    'de': 'Termin am {0} um {1} bei {2} absagen?',
    'fr': 'Annuler le rendez-vous du {0} à {1} avec {2} ?',
  },
  'Hora cancelada. Te enviamos la confirmación por correo.': {
    'en': 'Appointment cancelled. We sent you the confirmation by email.',
    'de': 'Termin abgesagt. Wir haben Ihnen die Bestätigung per E-Mail gesendet.',
    'fr': 'Rendez-vous annulé. Nous vous avons envoyé la confirmation par e-mail.',
  },
  'Hora cambiada. Te enviamos la confirmación por correo.': {
    'en': 'Appointment changed. We sent you the confirmation by email.',
    'de': 'Termin geändert. Wir haben Ihnen die Bestätigung per E-Mail gesendet.',
    'fr': 'Rendez-vous modifié. Nous vous avons envoyé la confirmation par e-mail.',
  },
  'Agendar hora para {0}': {
    'en': 'Book an appointment for {0}',
    'de': 'Termin für {0} buchen',
    'fr': 'Prendre rendez-vous pour {0}',
  },
  'Agendar hora': {
    'en': 'Book an appointment',
    'de': 'Termin buchen',
    'fr': 'Prendre rendez-vous',
  },
  'A domicilio': {
    'en': 'Home visit',
    'de': 'Hausbesuch',
    'fr': 'À domicile',
  },
  'Te atienden en casa': {
    'en': 'Seen at home',
    'de': 'Behandlung zu Hause',
    'fr': 'Soins à domicile',
  },
  'Presencial': {
    'en': 'In person',
    'de': 'Vor Ort',
    'fr': 'En présentiel',
  },
  'En un centro': {
    'en': 'At a center',
    'de': 'In einem Zentrum',
    'fr': 'Dans un centre',
  },
  'Telemedicina': {
    'en': 'Telemedicine',
    'de': 'Telemedizin',
    'fr': 'Télémédecine',
  },
  'Por videollamada': {
    'en': 'By video call',
    'de': 'Per Videoanruf',
    'fr': 'Par appel vidéo',
  },
  'Derma online': {
    'en': 'Online dermatology',
    'de': 'Online-Dermatologie',
    'fr': 'Dermato en ligne',
  },
  'Sin hora, con fotos': {
    'en': 'No appointment, with photos',
    'de': 'Ohne Termin, mit Fotos',
    'fr': 'Sans rendez-vous, avec photos',
  },
  'Horas agendadas de {0}': {
    'en': '{0}\'s appointments',
    'de': 'Termine von {0}',
    'fr': 'Rendez-vous de {0}',
  },
  'Tus horas agendadas': {
    'en': 'Your appointments',
    'de': 'Ihre Termine',
    'fr': 'Vos rendez-vous',
  },
  'Hora actual: {0} a las {1}': {
    'en': 'Current appointment: {0} at {1}',
    'de': 'Aktueller Termin: {0} um {1}',
    'fr': 'Rendez-vous actuel : {0} à {1}',
  },
  'Guardando…': {
    'en': 'Saving…',
    'de': 'Wird gespeichert…',
    'fr': 'Enregistrement…',
  },
  'Elige una hora': {
    'en': 'Choose a time',
    'de': 'Uhrzeit wählen',
    'fr': 'Choisissez une heure',
  },
  'Cambiar a las {0}': {
    'en': 'Change to {0}',
    'de': 'Auf {0} ändern',
    'fr': 'Changer pour {0}',
  },
  'Agendar para {0}': {
    'en': 'Book for {0}',
    'de': 'Für {0} buchen',
    'fr': 'Réserver pour {0}',
  },
  'Estás agendando para {0}: la reserva queda a su nombre.': {
    'en': 'You are booking for {0}: the booking will be in their name.',
    'de': 'Sie buchen für {0}: Die Buchung läuft auf deren Namen.',
    'fr': 'Vous réservez pour {0} : la réservation sera à son nom.',
  },
  '🏠 Agrega tu dirección': {
    'en': '🏠 Add your address',
    'de': '🏠 Adresse hinzufügen',
    'fr': '🏠 Ajoutez votre adresse',
  },
  '🏠 Actualiza tu dirección': {
    'en': '🏠 Update your address',
    'de': '🏠 Adresse aktualisieren',
    'fr': '🏠 Mettez à jour votre adresse',
  },
  'Para ver quién puede atenderte en tu casa necesitamos tu dirección (calle, número y comuna).': {
    'en': 'To see who can visit you at home we need your address (street, number and district).',
    'de': 'Um zu sehen, wer Sie zu Hause behandeln kann, benötigen wir Ihre Adresse (Straße, Hausnummer und Gemeinde).',
    'fr': 'Pour savoir qui peut venir chez vous, nous avons besoin de votre adresse (rue, numéro et commune).',
  },
  'A tu dirección registrada le falta la comuna. La necesitamos para saber quién puede ir a atenderte.': {
    'en': 'Your saved address is missing the district. We need it to know who can visit you.',
    'de': 'Bei Ihrer gespeicherten Adresse fehlt die Gemeinde. Wir brauchen sie, um zu wissen, wer Sie besuchen kann.',
    'fr': 'Il manque la commune à votre adresse enregistrée. Nous en avons besoin pour savoir qui peut venir vous soigner.',
  },
  'Agregar mi dirección': {
    'en': 'Add my address',
    'de': 'Meine Adresse hinzufügen',
    'fr': 'Ajouter mon adresse',
  },
  'Actualizar mi dirección': {
    'en': 'Update my address',
    'de': 'Meine Adresse aktualisieren',
    'fr': 'Mettre à jour mon adresse',
  },
  '🏠 Visita en {0}': {
    'en': '🏠 Visit at {0}',
    'de': '🏠 Besuch in {0}',
    'fr': '🏠 Visite à {0}',
  },
  'Ver centros más lejos ({0})': {
    'en': 'See centers farther away ({0})',
    'de': 'Weiter entfernte Zentren ansehen ({0})',
    'fr': 'Voir les centres plus éloignés ({0})',
  },
  'No hay centros a menos de 50 km de tu dirección.': {
    'en': 'There are no centers within 50 km of your address.',
    'de': 'Im Umkreis von 50 km um Ihre Adresse gibt es keine Zentren.',
    'fr': 'Aucun centre à moins de 50 km de votre adresse.',
  },
  'Por ahora no hay {0} disponible.': {
    'en': 'No {0} available for now.',
    'de': 'Derzeit ist keine {0} verfügbar.',
    'fr': 'Pas de {0} disponible pour le moment.',
  },
  '📍 Ordenado por cercanía a {0}': {
    'en': '📍 Sorted by distance from {0}',
    'de': '📍 Nach Entfernung zu {0} sortiert',
    'fr': '📍 Trié par proximité de {0}',
  },
  'Completa el pago: la hora queda apartada 30 minutos. También te llegó el link por correo.': {
    'en': 'Complete the payment: the slot is held for 30 minutes. The link was also sent to your email.',
    'de': 'Schließen Sie die Zahlung ab: Der Termin wird 30 Minuten reserviert. Der Link wurde Ihnen auch per E-Mail gesendet.',
    'fr': 'Finalisez le paiement : le créneau est réservé 30 minutes. Le lien vous a aussi été envoyé par e-mail.',
  },
  'Hora reservada. Te llegará la confirmación por correo.': {
    'en': 'Appointment booked. You will receive the confirmation by email.',
    'de': 'Termin gebucht. Sie erhalten die Bestätigung per E-Mail.',
    'fr': 'Rendez-vous réservé. Vous recevrez la confirmation par e-mail.',
  },
  'Consulta online · \${0}': {
    'en': 'Online consultation · \${0}',
    'de': 'Online-Sprechstunde · \${0}',
    'fr': 'Consultation en ligne · \${0}',
  },
  '🏠 Sale a {0} de tu domicilio': {
    'en': '🏠 Leaves {0} from your home',
    'de': '🏠 Startet {0} von Ihrer Wohnung entfernt',
    'fr': '🏠 Part à {0} de votre domicile',
  },
  'Cómo llegar': {
    'en': 'Directions',
    'de': 'Route',
    'fr': 'Itinéraire',
  },
  'No puedes autorizar acceso médico en nombre de esta persona.': {
    'en': 'You can\'t authorize doctor access on behalf of this person.',
    'de': 'Sie können für diese Person keinen Arztzugriff freigeben.',
    'fr': 'Vous ne pouvez pas autoriser l\'accès médical au nom de cette personne.',
  },
  'Ingresa el email del médico': {
    'en': 'Enter the doctor\'s email',
    'de': 'Geben Sie die E-Mail des Arztes ein',
    'fr': 'Saisissez l\'e-mail du médecin',
  },
  'Acceso enviado a {0}': {
    'en': 'Access sent to {0}',
    'de': 'Zugriff an {0} gesendet',
    'fr': 'Accès envoyé à {0}',
  },
  'Modo cuidador': {
    'en': 'Caregiver mode',
    'de': 'Betreuungsmodus',
    'fr': 'Mode aidant',
  },
  ' · Autorizando en nombre de {0}': {
    'en': ' · Authorizing on behalf of {0}',
    'de': ' · Freigabe im Namen von {0}',
    'fr': ' · Autorisation au nom de {0}',
  },
  'Genera un acceso temporal para que un médico revise tu ficha. Podrá revisarla por 3 horas. Al cerrar sesión el acceso expira.': {
    'en': 'Create temporary access for a doctor to review your record. They can review it for 3 hours. When the session closes, access expires.',
    'de': 'Erstellen Sie einen vorübergehenden Zugriff, damit ein Arzt Ihre Akte einsehen kann. Er kann sie 3 Stunden lang einsehen. Beim Beenden der Sitzung läuft der Zugriff ab.',
    'fr': 'Créez un accès temporaire pour qu\'un médecin consulte votre dossier. Il pourra le consulter pendant 3 heures. À la fermeture de la session, l\'accès expire.',
  },
  'Genera un acceso temporal para que un médico revise la ficha de {0}. Podrá revisarla por 3 horas. Al cerrar sesión el acceso expira.': {
    'en': 'Create temporary access for a doctor to review {0}\'s record. They can review it for 3 hours. When the session closes, access expires.',
    'de': 'Erstellen Sie einen vorübergehenden Zugriff, damit ein Arzt die Akte von {0} einsehen kann. Er kann sie 3 Stunden lang einsehen. Beim Beenden der Sitzung läuft der Zugriff ab.',
    'fr': 'Créez un accès temporaire pour qu\'un médecin consulte le dossier de {0}. Il pourra le consulter pendant 3 heures. À la fermeture de la session, l\'accès expire.',
  },
  'Genera un acceso temporal para que un médico revise la ficha del paciente. Podrá revisarla por 3 horas. Al cerrar sesión el acceso expira.': {
    'en': 'Create temporary access for a doctor to review the patient\'s record. They can review it for 3 hours. When the session closes, access expires.',
    'de': 'Erstellen Sie einen vorübergehenden Zugriff, damit ein Arzt die Akte des Patienten einsehen kann. Er kann sie 3 Stunden lang einsehen. Beim Beenden der Sitzung läuft der Zugriff ab.',
    'fr': 'Créez un accès temporaire pour qu\'un médecin consulte le dossier du patient. Il pourra le consulter pendant 3 heures. À la fermeture de la session, l\'accès expire.',
  },
  '📱 Código QR': {
    'en': '📱 QR code',
    'de': '📱 QR-Code',
    'fr': '📱 Code QR',
  },
  '📧 Email': {
    'en': '📧 Email',
    'de': '📧 E-Mail',
    'fr': '📧 E-mail',
  },
  '+ Generar código QR': {
    'en': '+ Generate QR code',
    'de': '+ QR-Code erstellen',
    'fr': '+ Générer un code QR',
  },
  'Enviar acceso por email': {
    'en': 'Send access by email',
    'de': 'Zugriff per E-Mail senden',
    'fr': 'Envoyer l\'accès par e-mail',
  },
  '👤 RUT {0}': {
    'en': '👤 RUT {0}',
    'de': '👤 RUT {0}',
    'fr': '👤 RUT {0}',
  },
  '⏱ Sesión activa hasta: {0}:{1}': {
    'en': '⏱ Session active until: {0}:{1}',
    'de': '⏱ Sitzung aktiv bis: {0}:{1}',
    'fr': '⏱ Session active jusqu\'à : {0}:{1}',
  },
  'Confirma que compartes la ficha bajo tu responsabilidad': {
    'en': 'Confirm that you share the record under your responsibility',
    'de': 'Bestätigen Sie, dass Sie die Akte in eigener Verantwortung teilen',
    'fr': 'Confirmez que vous partagez le dossier sous votre responsabilité',
  },
  'No se confirmó tu identidad.': {
    'en': 'Your identity was not confirmed.',
    'de': 'Ihre Identität wurde nicht bestätigt.',
    'fr': 'Votre identité n\'a pas été confirmée.',
  },
  '{0} Abre la ficha una vez con internet para guardarla en el teléfono.': {
    'en': '{0} Open the record once with internet to save it on the phone.',
    'de': '{0} Öffnen Sie die Akte einmal mit Internet, um sie auf dem Telefon zu speichern.',
    'fr': '{0} Ouvrez le dossier une fois avec internet pour l\'enregistrer sur le téléphone.',
  },
  'Voy a mostrar mi ficha clínica a un profesional de la salud sin conexión a internet. Lo hago por mi propia decisión y bajo mi responsabilidad. Sé que la identidad del profesional se verificará en el RNPI cuando vuelva la conexión, y que su nota no entrará a mi ficha hasta esa verificación.': {
    'en': 'I am going to show my medical record to a health professional without an internet connection. I do so by my own decision and under my responsibility. I know that the professional\'s identity will be verified in the RNPI when the connection returns, and that their note will not enter my record until that verification.',
    'de': 'Ich werde meine Krankenakte einer Gesundheitsfachperson ohne Internetverbindung zeigen. Ich tue dies aus eigener Entscheidung und in eigener Verantwortung. Mir ist bekannt, dass die Identität der Fachperson im RNPI geprüft wird, sobald wieder eine Verbindung besteht, und dass ihre Notiz erst nach dieser Prüfung in meine Akte aufgenommen wird.',
    'fr': 'Je vais montrer mon dossier médical à un professionnel de santé sans connexion internet. Je le fais de ma propre décision et sous ma responsabilité. Je sais que l\'identité du professionnel sera vérifiée dans le RNPI au retour de la connexion, et que sa note n\'entrera pas dans mon dossier avant cette vérification.',
  },
  'Voy a mostrar la ficha clínica de la persona que cuido a un profesional de la salud sin conexión a internet. Lo hago bajo mi responsabilidad como su cuidador. Sé que la identidad del profesional se verificará en el RNPI cuando vuelva la conexión, y que su nota no entrará a la ficha hasta esa verificación.': {
    'en': 'I am going to show the medical record of the person I care for to a health professional without an internet connection. I do so under my responsibility as their caregiver. I know that the professional\'s identity will be verified in the RNPI when the connection returns, and that their note will not enter the record until that verification.',
    'de': 'Ich werde die Krankenakte der von mir betreuten Person einer Gesundheitsfachperson ohne Internetverbindung zeigen. Ich tue dies in meiner Verantwortung als Betreuungsperson. Mir ist bekannt, dass die Identität der Fachperson im RNPI geprüft wird, sobald wieder eine Verbindung besteht, und dass ihre Notiz erst nach dieser Prüfung in die Akte aufgenommen wird.',
    'fr': 'Je vais montrer le dossier médical de la personne dont je m\'occupe à un professionnel de santé sans connexion internet. Je le fais sous ma responsabilité en tant qu\'aidant. Je sais que l\'identité du professionnel sera vérifiée dans le RNPI au retour de la connexion, et que sa note n\'entrera pas dans le dossier avant cette vérification.',
  },
  'Termina en {0}': {
    'en': 'Ends in {0}',
    'de': 'Endet in {0}',
    'fr': 'Se termine dans {0}',
  },
  'Red: {0}\nClave: {1}': {
    'en': 'Network: {0}\nPassword: {1}',
    'de': 'Netzwerk: {0}\nPasswort: {1}',
    'fr': 'Réseau : {0}\nMot de passe : {1}',
  },
  'Paso 2 de 2 · Abrir la ficha': {
    'en': 'Step 2 of 2 · Open the record',
    'de': 'Schritt 2 von 2 · Akte öffnen',
    'fr': 'Étape 2 sur 2 · Ouvrir le dossier',
  },
  'Abrir la ficha': {
    'en': 'Open the record',
    'de': 'Akte öffnen',
    'fr': 'Ouvrir le dossier',
  },
  'Ningún profesional ha entrado todavía.': {
    'en': 'No professional has signed in yet.',
    'de': 'Noch hat sich keine Fachperson angemeldet.',
    'fr': 'Aucun professionnel ne s\'est encore connecté.',
  },
  'Profesionales que entraron:': {
    'en': 'Professionals who signed in:',
    'de': 'Angemeldete Fachpersonen:',
    'fr': 'Professionnels connectés :',
  },
  'Notas guardadas: {0} — se enviarán solas cuando vuelva internet.': {
    'en': 'Saved notes: {0} — they will be sent automatically when internet returns.',
    'de': 'Gespeicherte Notizen: {0} — sie werden automatisch gesendet, sobald wieder Internet verfügbar ist.',
    'fr': 'Notes enregistrées : {0} — elles seront envoyées automatiquement au retour d\'internet.',
  },
  'Más económica': {
    'en': 'Cheapest',
    'de': 'Günstigste',
    'fr': 'La moins chère',
  },
  'Receta incompleta': {
    'en': 'Incomplete prescription',
    'de': 'Rezept unvollständig',
    'fr': 'Ordonnance incomplète',
  },
  '{0} — no disponible en esta farmacia': {
    'en': '{0} — not available at this pharmacy',
    'de': '{0} — in dieser Apotheke nicht verfügbar',
    'fr': '{0} — non disponible dans cette pharmacie',
  },
  'No se pudieron cargar tus recetas: {0}': {
    'en': 'Your prescriptions could not be loaded: {0}',
    'de': 'Ihre Rezepte konnten nicht geladen werden: {0}',
    'fr': 'Vos ordonnances n\'ont pas pu être chargées : {0}',
  },
  'No tienes recetas de los últimos {0} días\npara cotizar': {
    'en': 'You have no prescriptions from the last {0} days\nto compare',
    'de': 'Sie haben keine Rezepte aus den letzten {0} Tagen\nzum Vergleichen',
    'fr': 'Vous n\'avez pas d\'ordonnances des {0} derniers jours\nà comparer',
  },
  'Recetas con medicamentos ({0})': {
    'en': 'Prescriptions with medicines ({0})',
    'de': 'Rezepte mit Medikamenten ({0})',
    'fr': 'Ordonnances avec médicaments ({0})',
  },
  'Receta médica': {
    'en': 'Prescription',
    'de': 'Rezept',
    'fr': 'Ordonnance',
  },
  '1 medicamento — Ver cotización': {
    'en': '1 medicine — See prices',
    'de': '1 Medikament — Preise ansehen',
    'fr': '1 médicament — Voir les prix',
  },
  '{0} medicamentos — Ver cotización': {
    'en': '{0} medicines — See prices',
    'de': '{0} Medikamente — Preise ansehen',
    'fr': '{0} médicaments — Voir les prix',
  },
  'Cotización': {
    'en': 'Price comparison',
    'de': 'Preisvergleich',
    'fr': 'Comparaison des prix',
  },
  'Esta persona no te dio acceso a cotizar sus medicamentos.': {
    'en': 'This person did not give you access to compare their medicine prices.',
    'de': 'Diese Person hat Ihnen keinen Zugriff auf den Preisvergleich ihrer Medikamente gegeben.',
    'fr': 'Cette personne ne vous a pas donné accès à la comparaison des prix de ses médicaments.',
  },
  'No se pudo cargar: {0}': {
    'en': 'Could not load: {0}',
    'de': 'Konnte nicht geladen werden: {0}',
    'fr': 'Chargement impossible : {0}',
  },
  'Yo cuido': {
    'en': 'I care for',
    'de': 'Ich betreue',
    'fr': 'Je m\'occupe de',
  },
  'Personas que cuidas y tus invitaciones': {
    'en': 'People you care for and your invitations',
    'de': 'Personen, die Sie betreuen, und Ihre Einladungen',
    'fr': 'Personnes dont vous vous occupez et vos invitations',
  },
  'Me cuidan': {
    'en': 'My caregivers',
    'de': 'Meine Betreuer',
    'fr': 'Mes aidants',
  },
  'Quién puede ver tus recordatorios': {
    'en': 'Who can see your reminders',
    'de': 'Wer Ihre Erinnerungen sehen kann',
    'fr': 'Qui peut voir vos rappels',
  },
  '¿Cancelar la invitación a {0}?': {
    'en': 'Cancel the invitation to {0}?',
    'de': 'Einladung an {0} zurückziehen?',
    'fr': 'Annuler l\'invitation à {0} ?',
  },
  '¿Quitarle acceso a {0}? Ya no podrá ver tus notificaciones.': {
    'en': 'Remove {0}\'s access? They will no longer see your notifications.',
    'de': '{0} den Zugriff entziehen? Diese Person sieht Ihre Benachrichtigungen dann nicht mehr.',
    'fr': 'Retirer l\'accès à {0} ? Cette personne ne verra plus vos notifications.',
  },
  'Error: {0}': {
    'en': 'Error: {0}',
    'de': 'Fehler: {0}',
    'fr': 'Erreur : {0}',
  },
  'Vinculado': {
    'en': 'Linked',
    'de': 'Verknüpft',
    'fr': 'Associé',
  },
  'Esperando que acepte la invitación': {
    'en': 'Waiting for them to accept the invitation',
    'de': 'Warten auf Annahme der Einladung',
    'fr': 'En attente d\'acceptation de l\'invitation',
  },
  'Rechazó la invitación': {
    'en': 'Declined the invitation',
    'de': 'Einladung abgelehnt',
    'fr': 'A refusé l\'invitation',
  },
  'Expiró sin confirmar': {
    'en': 'Expired without confirmation',
    'de': 'Ohne Bestätigung abgelaufen',
    'fr': 'Expirée sans confirmation',
  },
  'No se pudieron cargar los niveles de acceso: {0}': {
    'en': 'Access levels could not be loaded: {0}',
    'de': 'Zugriffsstufen konnten nicht geladen werden: {0}',
    'fr': 'Les niveaux d\'accès n\'ont pas pu être chargés : {0}',
  },
  'Completa nombre, apellidos, RUT y nivel de acceso': {
    'en': 'Fill in first name, last name, RUT and access level',
    'de': 'Vorname, Nachname, RUT und Zugriffsstufe ausfüllen',
    'fr': 'Renseignez prénom, nom, RUT et niveau d\'accès',
  },
  'Ahora cuidas a {0}': {
    'en': 'You now care for {0}',
    'de': 'Sie betreuen jetzt {0}',
    'fr': 'Vous vous occupez maintenant de {0}',
  },
  'Invitación rechazada': {
    'en': 'Invitation declined',
    'de': 'Einladung abgelehnt',
    'fr': 'Invitation refusée',
  },
  '{0} te invita a ser su cuidador': {
    'en': '{0} invites you to be their caregiver',
    'de': '{0} lädt Sie ein, Betreuungsperson zu werden',
    'fr': '{0} vous invite à être son aidant',
  },
  'Podrás recibir {0}.': {
    'en': 'You will be able to receive {0}.',
    'de': 'Sie können {0} erhalten.',
    'fr': 'Vous pourrez recevoir {0}.',
  },
  '📩 {0} te invita a ser su cuidador': {
    'en': '📩 {0} invites you to be their caregiver',
    'de': '📩 {0} lädt Sie ein, Betreuungsperson zu werden',
    'fr': '📩 {0} vous invite à être son aidant',
  },
  'Acceso: {0}': {
    'en': 'Access: {0}',
    'de': 'Zugriff: {0}',
    'fr': 'Accès : {0}',
  },
  'Huella desactivada': {
    'en': 'Fingerprint turned off',
    'de': 'Fingerabdruck deaktiviert',
    'fr': 'Empreinte désactivée',
  },
  'Este teléfono no permite huella.': {
    'en': 'This phone does not support fingerprint.',
    'de': 'Dieses Telefon unterstützt keinen Fingerabdruck.',
    'fr': 'Ce téléphone ne prend pas en charge l\'empreinte.',
  },
  'No se pudo activar': {
    'en': 'Could not turn on',
    'de': 'Aktivierung fehlgeschlagen',
    'fr': 'Activation impossible',
  },
  'No se pudo conectar. Revisa tu conexión e intenta de nuevo.': {
    'en': 'Could not connect. Check your connection and try again.',
    'de': 'Verbindung fehlgeschlagen. Prüfen Sie Ihre Verbindung und versuchen Sie es erneut.',
    'fr': 'Connexion impossible. Vérifiez votre connexion et réessayez.',
  },
  'Confirma tu huella para activarla en MiSalud': {
    'en': 'Confirm your fingerprint to turn it on in MiSalud',
    'de': 'Bestätigen Sie Ihren Fingerabdruck, um ihn in MiSalud zu aktivieren',
    'fr': 'Confirmez votre empreinte pour l\'activer dans MiSalud',
  },
  'No se activó la huella': {
    'en': 'Fingerprint was not turned on',
    'de': 'Fingerabdruck wurde nicht aktiviert',
    'fr': 'L\'empreinte n\'a pas été activée',
  },
  'No se confirmó la huella.': {
    'en': 'Fingerprint was not confirmed.',
    'de': 'Fingerabdruck wurde nicht bestätigt.',
    'fr': 'L\'empreinte n\'a pas été confirmée.',
  },
  '✓ Huella activada': {
    'en': '✓ Fingerprint on',
    'de': '✓ Fingerabdruck aktiviert',
    'fr': '✓ Empreinte activée',
  },
  'La próxima vez entras con tu huella. Tus recordatorios seguirán sonando.': {
    'en': 'Next time you sign in with your fingerprint. Your reminders will keep ringing.',
    'de': 'Beim nächsten Mal melden Sie sich mit Fingerabdruck an. Ihre Erinnerungen klingeln weiterhin.',
    'fr': 'La prochaine fois, vous vous connecterez avec votre empreinte. Vos rappels continueront de sonner.',
  },
  'Tus recordatorios seguirán sonando en este teléfono.': {
    'en': 'Your reminders will keep ringing on this phone.',
    'de': 'Ihre Erinnerungen klingeln auf diesem Telefon weiterhin.',
    'fr': 'Vos rappels continueront de sonner sur ce téléphone.',
  },
  'Cuenta eliminada': {
    'en': 'Account deleted',
    'de': 'Konto gelöscht',
    'fr': 'Compte supprimé',
  },
  'No se pudo eliminar': {
    'en': 'Could not delete',
    'de': 'Löschen fehlgeschlagen',
    'fr': 'Suppression impossible',
  },
  'No se pudo confirmar. Toca el botón para intentar de nuevo.': {
    'en': 'Could not confirm. Tap the button to try again.',
    'de': 'Bestätigung fehlgeschlagen. Tippen Sie auf die Schaltfläche, um es erneut zu versuchen.',
    'fr': 'Confirmation impossible. Touchez le bouton pour réessayer.',
  },
  'Este teléfono ya no está vinculado. Ingresa con tu contraseña.': {
    'en': 'This phone is no longer linked. Sign in with your password.',
    'de': 'Dieses Telefon ist nicht mehr verknüpft. Melden Sie sich mit Ihrem Passwort an.',
    'fr': 'Ce téléphone n\'est plus associé. Connectez-vous avec votre mot de passe.',
  },
  'Confirma que eres tú para seguir.': {
    'en': 'Confirm it\'s you to continue.',
    'de': 'Bestätigen Sie, dass Sie es sind, um fortzufahren.',
    'fr': 'Confirmez que c\'est vous pour continuer.',
  },
  'Entra con tu huella para ver tu ficha.': {
    'en': 'Sign in with your fingerprint to see your record.',
    'de': 'Melden Sie sich mit Fingerabdruck an, um Ihre Akte zu sehen.',
    'fr': 'Connectez-vous avec votre empreinte pour voir votre dossier.',
  },
  'No se pudo cargar la lista de comunas. Revisa tu conexión.': {
    'en': 'The list of districts could not be loaded. Check your connection.',
    'de': 'Die Gemeindeliste konnte nicht geladen werden. Prüfen Sie Ihre Verbindung.',
    'fr': 'La liste des communes n\'a pas pu être chargée. Vérifiez votre connexion.',
  },
  'Escribe la calle.': {
    'en': 'Enter the street.',
    'de': 'Geben Sie die Straße ein.',
    'fr': 'Saisissez la rue.',
  },
  'Escribe el número (si no tiene, S/N).': {
    'en': 'Enter the number (if none, S/N).',
    'de': 'Geben Sie die Hausnummer ein (falls keine, S/N).',
    'fr': 'Saisissez le numéro (s\'il n\'y en a pas, S/N).',
  },
  'Elige la comuna de la lista.': {
    'en': 'Choose the district from the list.',
    'de': 'Wählen Sie die Gemeinde aus der Liste.',
    'fr': 'Choisissez la commune dans la liste.',
  },
  'No encontramos esa dirección.': {
    'en': 'We couldn\'t find that address.',
    'de': 'Wir konnten diese Adresse nicht finden.',
    'fr': 'Nous n\'avons pas trouvé cette adresse.',
  },
  'Sin conexión. Intenta de nuevo.': {
    'en': 'No connection. Try again.',
    'de': 'Keine Verbindung. Versuchen Sie es erneut.',
    'fr': 'Pas de connexion. Réessayez.',
  },
  'Calle': {
    'en': 'Street',
    'de': 'Straße',
    'fr': 'Rue',
  },
  'Número': {
    'en': 'Number',
    'de': 'Hausnummer',
    'fr': 'Numéro',
  },
  'Comuna': {
    'en': 'District (comuna)',
    'de': 'Gemeinde (Comuna)',
    'fr': 'Commune',
  },
  'Escribe y elige de la lista': {
    'en': 'Type and choose from the list',
    'de': 'Eingeben und aus der Liste wählen',
    'fr': 'Saisissez et choisissez dans la liste',
  },
  'Región: {0}': {
    'en': 'Region: {0}',
    'de': 'Region: {0}',
    'fr': 'Région : {0}',
  },
  'Elige una comuna de la lista': {
    'en': 'Choose a district from the list',
    'de': 'Wählen Sie eine Gemeinde aus der Liste',
    'fr': 'Choisissez une commune dans la liste',
  },
  'Depto / oficina (opcional)': {
    'en': 'Apt / office (optional)',
    'de': 'Wohnung / Büro (optional)',
    'fr': 'Appartement / bureau (facultatif)',
  },
  'Buscando…': {
    'en': 'Searching…',
    'de': 'Suche läuft…',
    'fr': 'Recherche…',
  },
  '✓ Sí, es aquí': {
    'en': '✓ Yes, it\'s here',
    'de': '✓ Ja, hier ist es',
    'fr': '✓ Oui, c\'est ici',
  },
  'Profesional no especificado': {
    'en': 'Professional not specified',
    'de': 'Fachperson nicht angegeben',
    'fr': 'Professionnel non précisé',
  },
  'Tipo de consulta: {0}': {
    'en': 'Type of consultation: {0}',
    'de': 'Art der Sprechstunde: {0}',
    'fr': 'Type de consultation : {0}',
  },
  'Diagnóstico': {
    'en': 'Diagnosis',
    'de': 'Diagnose',
    'fr': 'Diagnostic',
  },
  'Examen bucal': {
    'en': 'Oral examination',
    'de': 'Mundbefund',
    'fr': 'Examen buccal',
  },
  'Piezas tratadas': {
    'en': 'Treated teeth',
    'de': 'Behandelte Zähne',
    'fr': 'Dents traitées',
  },
  'Plan de tratamiento': {
    'en': 'Treatment plan',
    'de': 'Behandlungsplan',
    'fr': 'Plan de traitement',
  },
  'Examen físico': {
    'en': 'Physical examination',
    'de': 'Körperliche Untersuchung',
    'fr': 'Examen physique',
  },
  'Signos vitales': {
    'en': 'Vital signs',
    'de': 'Vitalzeichen',
    'fr': 'Signes vitaux',
  },
  'Procedimientos de enfermería': {
    'en': 'Nursing procedures',
    'de': 'Pflegemaßnahmen',
    'fr': 'Soins infirmiers',
  },
  'Evolución': {
    'en': 'Progress notes',
    'de': 'Verlauf',
    'fr': 'Évolution',
  },
  'Receta': {
    'en': 'Prescription',
    'de': 'Rezept',
    'fr': 'Ordonnance',
  },
  'Indicaciones': {
    'en': 'Instructions',
    'de': 'Anweisungen',
    'fr': 'Prescriptions',
  },
  'Exámenes': {
    'en': 'Tests',
    'de': 'Untersuchungen',
    'fr': 'Examens',
  },
  'Orden de kinesiología': {
    'en': 'Physiotherapy order',
    'de': 'Physiotherapie-Verordnung',
    'fr': 'Prescription de kinésithérapie',
  },
  'Orden kinésica': {
    'en': 'Physiotherapy order',
    'de': 'Physiotherapie-Verordnung',
    'fr': 'Prescription de kinésithérapie',
  },
  'Indicación quirúrgica': {
    'en': 'Surgical indication',
    'de': 'Operationsindikation',
    'fr': 'Indication chirurgicale',
  },
  'No se pudo abrir el PDF: {0}': {
    'en': 'The PDF could not be opened: {0}',
    'de': 'Das PDF konnte nicht geöffnet werden: {0}',
    'fr': 'Le PDF n\'a pas pu être ouvert : {0}',
  },
  '📸 Fotos ({0})': {
    'en': '📸 Photos ({0})',
    'de': '📸 Fotos ({0})',
    'fr': '📸 Photos ({0})',
  },
  ' · Viendo la ficha de {0}': {
    'en': ' · Viewing {0}\'s record',
    'de': ' · Akte von {0}',
    'fr': ' · Dossier de {0}',
  },
  'Sin conexión a internet y aún no hay una copia de tu ficha en este teléfono. Ábrela una vez con internet para guardarla.': {
    'en': 'No internet connection and there is no copy of your record on this phone yet. Open it once with internet to save it.',
    'de': 'Keine Internetverbindung und noch keine Kopie Ihrer Akte auf diesem Telefon. Öffnen Sie sie einmal mit Internet, um sie zu speichern.',
    'fr': 'Pas de connexion internet et pas encore de copie de votre dossier sur ce téléphone. Ouvrez-le une fois avec internet pour l\'enregistrer.',
  },
  'No se pudo cargar tu ficha: {0}': {
    'en': 'Your record could not be loaded: {0}',
    'de': 'Ihre Akte konnte nicht geladen werden: {0}',
    'fr': 'Votre dossier n\'a pas pu être chargé : {0}',
  },
  'Hola, {0} 👋': {
    'en': 'Hi, {0} 👋',
    'de': 'Hallo, {0} 👋',
    'fr': 'Bonjour, {0} 👋',
  },
  'Revisa tu historial médico explicado en lenguaje simple': {
    'en': 'Review your medical history explained in plain language',
    'de': 'Ihre Krankengeschichte in einfacher Sprache erklärt',
    'fr': 'Consultez votre historique médical expliqué simplement',
  },
  'Tu historial, explicado simple': {
    'en': 'Your history, explained simply',
    'de': 'Ihre Krankengeschichte, einfach erklärt',
    'fr': 'Votre historique, expliqué simplement',
  },
  '⚠️ Alergias': {
    'en': '⚠️ Allergies',
    'de': '⚠️ Allergien',
    'fr': '⚠️ Allergies',
  },
  'Sin alergias conocidas registradas': {
    'en': 'No known allergies recorded',
    'de': 'Keine bekannten Allergien erfasst',
    'fr': 'Aucune allergie connue enregistrée',
  },
  '💊 Medicamentos habituales': {
    'en': '💊 Regular medicines',
    'de': '💊 Dauermedikation',
    'fr': '💊 Traitements habituels',
  },
  'Sin medicamentos habituales registrados': {
    'en': 'No regular medicines recorded',
    'de': 'Keine Dauermedikation erfasst',
    'fr': 'Aucun traitement habituel enregistré',
  },
  '🩺 Enfermedades crónicas': {
    'en': '🩺 Chronic conditions',
    'de': '🩺 Chronische Erkrankungen',
    'fr': '🩺 Maladies chroniques',
  },
  'Sin enfermedades crónicas registradas': {
    'en': 'No chronic conditions recorded',
    'de': 'Keine chronischen Erkrankungen erfasst',
    'fr': 'Aucune maladie chronique enregistrée',
  },
  '📸 1 foto': {
    'en': '📸 1 photo',
    'de': '📸 1 Foto',
    'fr': '📸 1 photo',
  },
  '📸 {0} fotos': {
    'en': '📸 {0} photos',
    'de': '📸 {0} Fotos',
    'fr': '📸 {0} photos',
  },
  'No se pudieron cargar más atenciones: {0}': {
    'en': 'More consultations could not be loaded: {0}',
    'de': 'Weitere Sprechstunden konnten nicht geladen werden: {0}',
    'fr': 'Impossible de charger plus de consultations : {0}',
  },
  '{0} consultas registradas': {
    'en': '{0} consultations recorded',
    'de': '{0} Sprechstunden erfasst',
    'fr': '{0} consultations enregistrées',
  },
  ' · última: {0}': {
    'en': ' · latest: {0}',
    'de': ' · letzte: {0}',
    'fr': ' · dernière : {0}',
  },
  'Tus consultas ({0})': {
    'en': 'Your consultations ({0})',
    'de': 'Ihre Sprechstunden ({0})',
    'fr': 'Vos consultations ({0})',
  },
  'Cargando…': {
    'en': 'Loading…',
    'de': 'Wird geladen…',
    'fr': 'Chargement…',
  },
  'Ver más atenciones': {
    'en': 'See more consultations',
    'de': 'Weitere Sprechstunden ansehen',
    'fr': 'Voir plus de consultations',
  },
  'Desde {0}': {
    'en': 'Since {0}',
    'de': 'Seit {0}',
    'fr': 'Depuis {0}',
  },
  'Este nivel de acceso solo autoriza ver medicamentos y controles.\nRevisa la pestaña "Recordatorios".': {
    'en': 'This access level only allows seeing medicines and check-ups.\nSee the "Reminders" tab.',
    'de': 'Diese Zugriffsstufe erlaubt nur Medikamente und Kontrollen.\nSiehe Reiter "Erinnerungen".',
    'fr': 'Ce niveau d\'accès permet seulement de voir les médicaments et les contrôles.\nConsultez l\'onglet "Rappels".',
  },
  'Sin indicaciones registradas': {
    'en': 'No instructions recorded',
    'de': 'Keine Anweisungen erfasst',
    'fr': 'Aucune prescription enregistrée',
  },
  '⚠️ ALERGIAS': {
    'en': '⚠️ ALLERGIES',
    'de': '⚠️ ALLERGIEN',
    'fr': '⚠️ ALLERGIES',
  },
  'Sin alergias conocidas': {
    'en': 'No known allergies',
    'de': 'Keine bekannten Allergien',
    'fr': 'Aucune allergie connue',
  },
  '💊 MEDICAMENTOS': {
    'en': '💊 MEDICINES',
    'de': '💊 MEDIKAMENTE',
    'fr': '💊 MÉDICAMENTS',
  },
  'Sin medicamentos habituales': {
    'en': 'No regular medicines',
    'de': 'Keine Dauermedikation',
    'fr': 'Aucun traitement habituel',
  },
  '🩺 CRÓNICAS': {
    'en': '🩺 CHRONIC',
    'de': '🩺 CHRONISCH',
    'fr': '🩺 CHRONIQUES',
  },
  'Sin enfermedades crónicas': {
    'en': 'No chronic conditions',
    'de': 'Keine chronischen Erkrankungen',
    'fr': 'Aucune maladie chronique',
  },
  '1 consulta registrada': {
    'en': '1 consultation recorded',
    'de': '1 Sprechstunde erfasst',
    'fr': '1 consultation enregistrée',
  },
  'Esta persona no te dio acceso a su ficha clínica completa.': {
    'en': 'This person did not give you access to their full medical record.',
    'de': 'Diese Person hat Ihnen keinen Zugriff auf ihre vollständige Krankenakte gegeben.',
    'fr': 'Cette personne ne vous a pas donné accès à son dossier médical complet.',
  },
  'Consulta': {
    'en': 'Consultation',
    'de': 'Sprechstunde',
    'fr': 'Consultation',
  },
  'Diagnóstico: ': {
    'en': 'Diagnosis: ',
    'de': 'Diagnose: ',
    'fr': 'Diagnostic : ',
  },
  'Ocultar': {
    'en': 'Hide',
    'de': 'Ausblenden',
    'fr': 'Masquer',
  },
  'Ver detalle': {
    'en': 'See details',
    'de': 'Details ansehen',
    'fr': 'Voir le détail',
  },
  '⬇ PDF': {
    'en': '⬇ PDF',
    'de': '⬇ PDF',
    'fr': '⬇ PDF',
  },
  'Sin internet: compartir con el computador del médico': {
    'en': 'No internet: share with the doctor\'s computer',
    'de': 'Ohne Internet: mit dem Computer des Arztes teilen',
    'fr': 'Sans internet : partager avec l\'ordinateur du médecin',
  },
  'Voy a mostrar mi ficha clínica a un profesional de la salud sin conexión a internet. Lo hago por mi propia decisión y bajo mi responsabilidad. Sé que su identidad se verificará en el RNPI cuando vuelva la conexión, y que su nota no entrará a mi ficha hasta esa verificación.': {
    'en': 'I am going to show my medical record to a health professional without an internet connection. I do so by my own decision and under my responsibility. I know that their identity will be verified in the RNPI when the connection returns, and that their note will not enter my record until that verification.',
    'de': 'Ich werde meine Krankenakte einer Gesundheitsfachperson ohne Internetverbindung zeigen. Ich tue dies aus eigener Entscheidung und in eigener Verantwortung. Mir ist bekannt, dass ihre Identität im RNPI geprüft wird, sobald wieder eine Verbindung besteht, und dass ihre Notiz erst nach dieser Prüfung in meine Akte aufgenommen wird.',
    'fr': 'Je vais montrer mon dossier médical à un professionnel de santé sans connexion internet. Je le fais de ma propre décision et sous ma responsabilité. Je sais que son identité sera vérifiée dans le RNPI au retour de la connexion, et que sa note n\'entrera pas dans mon dossier avant cette vérification.',
  },
  'Voy a mostrar la ficha clínica de la persona que cuido a un profesional de la salud sin conexión a internet, bajo mi responsabilidad como su cuidador. Sé que su identidad se verificará en el RNPI cuando vuelva la conexión, y que su nota no entrará a la ficha hasta esa verificación.': {
    'en': 'I am going to show the medical record of the person I care for to a health professional without an internet connection, under my responsibility as their caregiver. I know that their identity will be verified in the RNPI when the connection returns, and that their note will not enter the record until that verification.',
    'de': 'Ich werde die Krankenakte der von mir betreuten Person einer Gesundheitsfachperson ohne Internetverbindung zeigen, in meiner Verantwortung als Betreuungsperson. Mir ist bekannt, dass ihre Identität im RNPI geprüft wird, sobald wieder eine Verbindung besteht, und dass ihre Notiz erst nach dieser Prüfung in die Akte aufgenommen wird.',
    'fr': 'Je vais montrer le dossier médical de la personne dont je m\'occupe à un professionnel de santé sans connexion internet, sous ma responsabilité en tant qu\'aidant. Je sais que son identité sera vérifiée dans le RNPI au retour de la connexion, et que sa note n\'entrera pas dans le dossier avant cette vérification.',
  },
  'Esperando al computador del médico…': {
    'en': 'Waiting for the doctor\'s computer…',
    'de': 'Warten auf den Computer des Arztes…',
    'fr': 'En attente de l\'ordinateur du médecin…',
  },
  'No se encontró el computador del médico': {
    'en': 'The doctor\'s computer was not found',
    'de': 'Der Computer des Arztes wurde nicht gefunden',
    'fr': 'L\'ordinateur du médecin est introuvable',
  },
  'Bluetooth: {0}': {
    'en': 'Bluetooth: {0}',
    'de': 'Bluetooth: {0}',
    'fr': 'Bluetooth : {0}',
  },
  'Conectando…': {
    'en': 'Connecting…',
    'de': 'Verbindung wird hergestellt…',
    'fr': 'Connexion…',
  },
  'Verifica el código': {
    'en': 'Check the code',
    'de': 'Code prüfen',
    'fr': 'Vérifiez le code',
  },
  'Consulta en curso': {
    'en': 'Consultation in progress',
    'de': 'Sprechstunde läuft',
    'fr': 'Consultation en cours',
  },
  'Computador: {0}': {
    'en': 'Computer: {0}',
    'de': 'Computer: {0}',
    'fr': 'Ordinateur : {0}',
  },
  'El médico aún no se identifica.': {
    'en': 'The doctor has not identified themselves yet.',
    'de': 'Der Arzt hat sich noch nicht identifiziert.',
    'fr': 'Le médecin ne s\'est pas encore identifié.',
  },
  'Profesionales:': {
    'en': 'Professionals:',
    'de': 'Fachpersonen:',
    'fr': 'Professionnels :',
  },
  'El médico no aceptó': {
    'en': 'The doctor did not accept',
    'de': 'Der Arzt hat nicht angenommen',
    'fr': 'Le médecin n\'a pas accepté',
  },
  'Consulta terminada': {
    'en': 'Consultation finished',
    'de': 'Sprechstunde beendet',
    'fr': 'Consultation terminée',
  },
  'Se guardaron {0} nota(s). Se enviarán solas cuando vuelva internet.': {
    'en': '{0} note(s) saved. They will be sent automatically when internet returns.',
    'de': '{0} Notiz(en) gespeichert. Sie werden automatisch gesendet, sobald wieder Internet verfügbar ist.',
    'fr': '{0} note(s) enregistrée(s). Elles seront envoyées automatiquement au retour d\'internet.',
  },
  'El computador ya no tiene acceso a la ficha.': {
    'en': 'The computer no longer has access to the record.',
    'de': 'Der Computer hat keinen Zugriff mehr auf die Akte.',
    'fr': 'L\'ordinateur n\'a plus accès au dossier.',
  },
  'Ingresa tu RUT y tu contraseña': {
    'en': 'Enter your RUT and password',
    'de': 'Geben Sie Ihre RUT und Ihr Passwort ein',
    'fr': 'Saisissez votre RUT et votre mot de passe',
  },
  'El RUT ingresado no es válido': {
    'en': 'The RUT entered is not valid',
    'de': 'Die eingegebene RUT ist ungültig',
    'fr': 'Le RUT saisi n\'est pas valide',
  },
  'No se pudo conectar. Revisa tu conexión.': {
    'en': 'Could not connect. Check your connection.',
    'de': 'Verbindung fehlgeschlagen. Prüfen Sie Ihre Verbindung.',
    'fr': 'Connexion impossible. Vérifiez votre connexion.',
  },
  'Escribe los 6 dígitos que llegaron a tu correo': {
    'en': 'Enter the 6 digits sent to your email',
    'de': 'Geben Sie die 6 Ziffern aus Ihrer E-Mail ein',
    'fr': 'Saisissez les 6 chiffres reçus par e-mail',
  },
  'Sin medicamentos ni controles vigentes': {
    'en': 'No current medicines or check-ups',
    'de': 'Keine aktuellen Medikamente oder Kontrollen',
    'fr': 'Aucun médicament ni contrôle en cours',
  },
  '⏰ Próxima toma: {0}': {
    'en': '⏰ Next dose: {0}',
    'de': '⏰ Nächste Einnahme: {0}',
    'fr': '⏰ Prochaine prise : {0}',
  },
  'Cada {0}h': {
    'en': 'Every {0}h',
    'de': 'Alle {0} Std.',
    'fr': 'Toutes les {0} h',
  },
  ' · {0} días de tratamiento': {
    'en': ' · {0} days of treatment',
    'de': ' · {0} Behandlungstage',
    'fr': ' · {0} jours de traitement',
  },
  'Citas agendadas': {
    'en': 'Booked appointments',
    'de': 'Gebuchte Termine',
    'fr': 'Rendez-vous pris',
  },
  'No se pudieron cargar los recordatorios:\n{0}': {
    'en': 'Reminders could not be loaded:\n{0}',
    'de': 'Erinnerungen konnten nicht geladen werden:\n{0}',
    'fr': 'Les rappels n\'ont pas pu être chargés :\n{0}',
  },
  'Próximas 2 horas': {
    'en': 'Next 2 hours',
    'de': 'Nächste 2 Stunden',
    'fr': '2 prochaines heures',
  },
  'Próximas tomas': {
    'en': 'Upcoming doses',
    'de': 'Nächste Einnahmen',
    'fr': 'Prochaines prises',
  },
  'Sin próxima toma': {
    'en': 'No upcoming dose',
    'de': 'Keine nächste Einnahme',
    'fr': 'Aucune prochaine prise',
  },
  'Hoy a las {0}': {
    'en': 'Today at {0}',
    'de': 'Heute um {0}',
    'fr': 'Aujourd\'hui à {0}',
  },
  'Mañana a las {0}': {
    'en': 'Tomorrow at {0}',
    'de': 'Morgen um {0}',
    'fr': 'Demain à {0}',
  },
  '{0} a las {1}': {
    'en': '{0} at {1}',
    'de': '{0} um {1}',
    'fr': '{0} à {1}',
  },
  ' · {0} días': {
    'en': ' · {0} days',
    'de': ' · {0} Tage',
    'fr': ' · {0} jours',
  },
  'No se pudo cargar la página de reservas.': {
    'en': 'The booking page could not be loaded.',
    'de': 'Die Buchungsseite konnte nicht geladen werden.',
    'fr': 'La page de réservation n\'a pas pu être chargée.',
  },
  'Compara precios de las recetas de {0}': {
    'en': 'Compare prices of {0}\'s prescriptions',
    'de': 'Preise der Rezepte von {0} vergleichen',
    'fr': 'Comparez les prix des ordonnances de {0}',
  },
  'No hay recetas de los últimos {0} días\npara cotizar': {
    'en': 'There are no prescriptions from the last {0} days\nto compare',
    'de': 'Keine Rezepte aus den letzten {0} Tagen\nzum Vergleichen',
    'fr': 'Aucune ordonnance des {0} derniers jours\nà comparer',
  },
  'No pudimos conectar con el servidor. Intenta de nuevo en un momento ({0}).': {
    'en': 'We couldn\'t connect to the server. Try again in a moment ({0}).',
    'de': 'Keine Verbindung zum Server. Versuchen Sie es gleich noch einmal ({0}).',
    'fr': 'Impossible de joindre le serveur. Réessayez dans un instant ({0}).',
  },
  'Error inesperado ({0})': {
    'en': 'Unexpected error ({0})',
    'de': 'Unerwarteter Fehler ({0})',
    'fr': 'Erreur inattendue ({0})',
  },
  '🏠 A domicilio': {
    'en': '🏠 Home visit',
    'de': '🏠 Hausbesuch',
    'fr': '🏠 À domicile',
  },
  '💻 Telemedicina': {
    'en': '💻 Telemedicine',
    'de': '💻 Telemedizin',
    'fr': '💻 Télémédecine',
  },
  '🏥 Presencial': {
    'en': '🏥 In person',
    'de': '🏥 Vor Ort',
    'fr': '🏥 En présentiel',
  },
  'No se pudieron cargar tus horas': {
    'en': 'Your appointments could not be loaded',
    'de': 'Ihre Termine konnten nicht geladen werden',
    'fr': 'Vos rendez-vous n\'ont pas pu être chargés',
  },
  'No se pudieron cargar las horas': {
    'en': 'The time slots could not be loaded',
    'de': 'Die Termine konnten nicht geladen werden',
    'fr': 'Les créneaux n\'ont pas pu être chargés',
  },
  'No se pudo cancelar la hora': {
    'en': 'The appointment could not be cancelled',
    'de': 'Der Termin konnte nicht abgesagt werden',
    'fr': 'Le rendez-vous n\'a pas pu être annulé',
  },
  'No se pudo cambiar la hora': {
    'en': 'The appointment could not be changed',
    'de': 'Der Termin konnte nicht geändert werden',
    'fr': 'Le rendez-vous n\'a pas pu être modifié',
  },
  'No se pudieron cargar los centros ({0})': {
    'en': 'The centers could not be loaded ({0})',
    'de': 'Die Zentren konnten nicht geladen werden ({0})',
    'fr': 'Les centres n\'ont pas pu être chargés ({0})',
  },
  'Hora de tu medicamento': {
    'en': 'Time for your medicine',
    'de': 'Zeit für Ihr Medikament',
    'fr': 'C\'est l\'heure de votre médicament',
  },
  '🏃 Hora de tu ejercicio': {
    'en': '🏃 Time for your exercise',
    'de': '🏃 Zeit für Ihre Übung',
    'fr': '🏃 C\'est l\'heure de votre exercice',
  },
  'Si el RUT corresponde a una ficha registrada, se enviarán instrucciones al correo asociado.': {
    'en': 'If the RUT matches a registered record, instructions will be sent to the associated email.',
    'de': 'Wenn die RUT zu einer registrierten Akte gehört, werden Anweisungen an die verknüpfte E-Mail gesendet.',
    'fr': 'Si le RUT correspond à un dossier enregistré, des instructions seront envoyées à l\'e-mail associé.',
  },
  'Este teléfono no está vinculado': {
    'en': 'This phone is not linked',
    'de': 'Dieses Telefon ist nicht verknüpft',
    'fr': 'Ce téléphone n\'est pas associé',
  },
  'Tu cuenta fue eliminada.': {
    'en': 'Your account was deleted.',
    'de': 'Ihr Konto wurde gelöscht.',
    'fr': 'Votre compte a été supprimé.',
  },
  'El teléfono no tiene huella, rostro ni bloqueo de pantalla configurado.': {
    'en': 'The phone has no fingerprint, face or screen lock set up.',
    'de': 'Auf dem Telefon ist weder Fingerabdruck, Gesichtserkennung noch Bildschirmsperre eingerichtet.',
    'fr': 'Le téléphone n\'a ni empreinte, ni visage, ni verrouillage d\'écran configuré.',
  },
  'No se pudo revisar la huella del teléfono ({0}).': {
    'en': 'The phone\'s fingerprint could not be checked ({0}).',
    'de': 'Der Fingerabdruck des Telefons konnte nicht geprüft werden ({0}).',
    'fr': 'L\'empreinte du téléphone n\'a pas pu être vérifiée ({0}).',
  },
  'La huella no está disponible: {0}': {
    'en': 'Fingerprint is not available: {0}',
    'de': 'Fingerabdruck nicht verfügbar: {0}',
    'fr': 'L\'empreinte n\'est pas disponible : {0}',
  },
  'La consulta sin conexión por red local está disponible solo en Android.': {
    'en': 'Offline consultation over a local network is only available on Android.',
    'de': 'Die Offline-Sprechstunde über lokales Netzwerk ist nur auf Android verfügbar.',
    'fr': 'La consultation hors ligne par réseau local n\'est disponible que sur Android.',
  },
  'No se pudo crear la red local. Activa el Wi-Fi del teléfono e intenta de nuevo, o conéctalo a la misma red Wi-Fi que el equipo del profesional.': {
    'en': 'The local network could not be created. Turn on the phone\'s Wi-Fi and try again, or connect it to the same Wi-Fi network as the professional\'s computer.',
    'de': 'Das lokale Netzwerk konnte nicht erstellt werden. Schalten Sie das WLAN des Telefons ein und versuchen Sie es erneut, oder verbinden Sie es mit demselben WLAN wie den Computer der Fachperson.',
    'fr': 'Le réseau local n\'a pas pu être créé. Activez le Wi-Fi du téléphone et réessayez, ou connectez-le au même réseau Wi-Fi que l\'ordinateur du professionnel.',
  },
  'Términos de uso': {
    'en': 'Terms of use',
    'de': 'Nutzungsbedingungen',
    'fr': 'Conditions d\'utilisation',
  },
  'No se pudo registrar': {
    'en': 'Could not be recorded',
    'de': 'Konnte nicht gespeichert werden',
    'fr': 'Enregistrement impossible',
  },
  'Para guardar tu ficha en este teléfono, activa un bloqueo de pantalla (huella, rostro o PIN).': {
    'en': 'To save your record on this phone, turn on a screen lock (fingerprint, face or PIN).',
    'de': 'Um Ihre Akte auf diesem Telefon zu speichern, aktivieren Sie eine Bildschirmsperre (Fingerabdruck, Gesicht oder PIN).',
    'fr': 'Pour enregistrer votre dossier sur ce téléphone, activez un verrouillage d\'écran (empreinte, visage ou code PIN).',
  },
  'Ya no tienes acceso a la ficha de esta persona': {
    'en': 'You no longer have access to this person\'s record',
    'de': 'Sie haben keinen Zugriff mehr auf die Akte dieser Person',
    'fr': 'Vous n\'avez plus accès au dossier de cette personne',
  },
  'No se pudo descargar la copia ({0})': {
    'en': 'The copy could not be downloaded ({0})',
    'de': 'Die Kopie konnte nicht heruntergeladen werden ({0})',
    'fr': 'La copie n\'a pas pu être téléchargée ({0})',
  },
  'La copia recibida está incompleta': {
    'en': 'The copy received is incomplete',
    'de': 'Die empfangene Kopie ist unvollständig',
    'fr': 'La copie reçue est incomplète',
  },
  'Confirma que eres tú para abrir la ficha': {
    'en': 'Confirm it\'s you to open the record',
    'de': 'Bestätigen Sie, dass Sie es sind, um die Akte zu öffnen',
    'fr': 'Confirmez que c\'est vous pour ouvrir le dossier',
  },
  'No hay una copia de tu ficha guardada en este teléfono.': {
    'en': 'There is no copy of your record saved on this phone.',
    'de': 'Auf diesem Telefon ist keine Kopie Ihrer Akte gespeichert.',
    'fr': 'Aucune copie de votre dossier n\'est enregistrée sur ce téléphone.',
  },
  'No hay una copia de la ficha de esta persona en este teléfono.': {
    'en': 'There is no copy of this person\'s record on this phone.',
    'de': 'Auf diesem Telefon ist keine Kopie der Akte dieser Person.',
    'fr': 'Aucune copie du dossier de cette personne sur ce téléphone.',
  },
  'La copia guardada no es válida.': {
    'en': 'The saved copy is not valid.',
    'de': 'Die gespeicherte Kopie ist ungültig.',
    'fr': 'La copie enregistrée n\'est pas valide.',
  },
  'La copia guardada está dañada o fue modificada. Conéctate a internet para descargarla de nuevo.': {
    'en': 'The saved copy is damaged or was modified. Connect to the internet to download it again.',
    'de': 'Die gespeicherte Kopie ist beschädigt oder wurde verändert. Verbinden Sie sich mit dem Internet, um sie erneut herunterzuladen.',
    'fr': 'La copie enregistrée est endommagée ou a été modifiée. Connectez-vous à internet pour la télécharger à nouveau.',
  },
  'No se pudo abrir la copia guardada.': {
    'en': 'The saved copy could not be opened.',
    'de': 'Die gespeicherte Kopie konnte nicht geöffnet werden.',
    'fr': 'La copie enregistrée n\'a pas pu être ouverte.',
  },
  'No se pudo cargar la ficha ({0})': {
    'en': 'The record could not be loaded ({0})',
    'de': 'Die Akte konnte nicht geladen werden ({0})',
    'fr': 'Le dossier n\'a pas pu être chargé ({0})',
  },
  'Error al conectar ({0})': {
    'en': 'Connection error ({0})',
    'de': 'Verbindungsfehler ({0})',
    'fr': 'Erreur de connexion ({0})',
  },
  'Sin conexión a internet. Este servicio necesita red; tu ficha guardada en el teléfono sigue disponible.': {
    'en': 'No internet connection. This service needs a network; your record saved on the phone is still available.',
    'de': 'Keine Internetverbindung. Dieser Dienst braucht ein Netzwerk; Ihre auf dem Telefon gespeicherte Akte bleibt verfügbar.',
    'fr': 'Pas de connexion internet. Ce service nécessite un réseau ; votre dossier enregistré sur le téléphone reste disponible.',
  },
  'error desconocido': {
    'en': 'unknown error',
    'de': 'unbekannter Fehler',
    'fr': 'erreur inconnue',
  },
  'El lector no respondió.': {
    'en': 'The reader did not respond.',
    'de': 'Das Lesegerät hat nicht geantwortet.',
    'fr': 'Le lecteur n\'a pas répondu.',
  },
  'El médico no aceptó a tiempo.': {
    'en': 'The doctor did not accept in time.',
    'de': 'Der Arzt hat nicht rechtzeitig angenommen.',
    'fr': 'Le médecin n\'a pas accepté à temps.',
  },
  'No se pudieron cargar los recordatorios ({0})': {
    'en': 'Reminders could not be loaded ({0})',
    'de': 'Erinnerungen konnten nicht geladen werden ({0})',
    'fr': 'Les rappels n\'ont pas pu être chargés ({0})',
  },
  'No se pudieron generar los recordatorios ({0})': {
    'en': 'Reminders could not be created ({0})',
    'de': 'Erinnerungen konnten nicht erstellt werden ({0})',
    'fr': 'Les rappels n\'ont pas pu être créés ({0})',
  },
  'No se pudo revisar la agenda ({0})': {
    'en': 'The schedule could not be checked ({0})',
    'de': 'Der Kalender konnte nicht geprüft werden ({0})',
    'fr': 'L\'agenda n\'a pas pu être vérifié ({0})',
  },
  'Este recordatorio ya fue editado antes y no se puede modificar de nuevo': {
    'en': 'This reminder was already edited and cannot be changed again',
    'de': 'Diese Erinnerung wurde bereits bearbeitet und kann nicht erneut geändert werden',
    'fr': 'Ce rappel a déjà été modifié et ne peut plus l\'être',
  },
  'No se pudo editar el recordatorio ({0})': {
    'en': 'The reminder could not be edited ({0})',
    'de': 'Die Erinnerung konnte nicht bearbeitet werden ({0})',
    'fr': 'Le rappel n\'a pas pu être modifié ({0})',
  },
  'Idioma no disponible': {
    'en': 'Language not available',
    'de': 'Sprache nicht verfügbar',
    'fr': 'Langue non disponible',
  },
  'El idioma no está descargado en el teléfono (se baja solo con Wi-Fi)': {
    'en': 'The language is not downloaded on the phone (it downloads only on Wi-Fi)',
    'de': 'Die Sprache ist nicht auf dem Telefon heruntergeladen (Download nur über WLAN)',
    'fr': 'La langue n\'est pas téléchargée sur le téléphone (téléchargement uniquement en Wi-Fi)',
  },
  'Sin acceso a esto para {0}': {
    'en': 'No access to this for {0}',
    'de': 'Kein Zugriff darauf für {0}',
    'fr': 'Pas d\'accès à ceci pour {0}',
  },
  'Actualizamos los términos. ': {
    'en': 'We updated the terms. ',
    'de': 'Wir haben die Bedingungen aktualisiert. ',
    'fr': 'Nous avons mis à jour les conditions. ',
  },
  'Léelos y acéptalos para seguir usando el Portal. Te enviaremos una copia por correo.': {
    'en': 'Read and accept them to keep using the Portal. We will send you a copy by email.',
    'de': 'Lesen und akzeptieren Sie sie, um das Portal weiter zu nutzen. Wir senden Ihnen eine Kopie per E-Mail.',
    'fr': 'Lisez-les et acceptez-les pour continuer à utiliser le Portail. Nous vous enverrons une copie par e-mail.',
  },
  '📍 El profesional llegó': {
    'en': '📍 The professional has arrived',
    'de': '📍 Die Fachperson ist angekommen',
    'fr': '📍 Le professionnel est arrivé',
  },
  '🚗 Tu profesional va en camino': {
    'en': '🚗 Your professional is on the way',
    'de': '🚗 Ihre Fachperson ist unterwegs',
    'fr': '🚗 Votre professionnel est en route',
  },
  '🏠 Visita a domicilio confirmada': {
    'en': '🏠 Home visit confirmed',
    'de': '🏠 Hausbesuch bestätigt',
    'fr': '🏠 Visite à domicile confirmée',
  },
  'Llega en aproximadamente {0} min': {
    'en': 'Arrives in about {0} min',
    'de': 'Ankunft in etwa {0} Min.',
    'fr': 'Arrive dans environ {0} min',
  },
  'Tu profesional va en camino': {
    'en': 'Your professional is on the way',
    'de': 'Ihre Fachperson ist unterwegs',
    'fr': 'Votre professionnel est en route',
  },
  'Seguimiento de tu visita': {
    'en': 'Track your visit',
    'de': 'Verfolgung Ihres Besuchs',
    'fr': 'Suivi de votre visite',
  },
  'Pendiente de pago': {
    'en': 'Payment pending',
    'de': 'Zahlung ausstehend',
    'fr': 'Paiement en attente',
  },
  'Por confirmar': {
    'en': 'To be confirmed',
    'de': 'Zu bestätigen',
    'fr': 'À confirmer',
  },
  'Confirmada': {
    'en': 'Confirmed',
    'de': 'Bestätigt',
    'fr': 'Confirmée',
  },
  'Reservada': {
    'en': 'Booked',
    'de': 'Gebucht',
    'fr': 'Réservée',
  },
  '🔬 Cirugías': {
    'en': '🔬 Surgeries',
    'de': '🔬 Operationen',
    'fr': '🔬 Chirurgies',
  },
  'Sin cirugías registradas': {
    'en': 'No surgeries recorded',
    'de': 'Keine Operationen erfasst',
    'fr': 'Aucune chirurgie enregistrée',
  },
  '👨‍👩‍👧 Antecedentes familiares': {
    'en': '👨‍👩‍👧 Family history',
    'de': '👨‍👩‍👧 Familienanamnese',
    'fr': '👨‍👩‍👧 Antécédents familiaux',
  },
  'Sin antecedentes familiares registrados': {
    'en': 'No family history recorded',
    'de': 'Keine Familienanamnese erfasst',
    'fr': 'Aucun antécédent familial enregistré',
  },
  '📋 Otros antecedentes': {
    'en': '📋 Other history',
    'de': '📋 Sonstige Vorgeschichte',
    'fr': '📋 Autres antécédents',
  },
  'Sin otros antecedentes registrados': {
    'en': 'No other history recorded',
    'de': 'Keine sonstige Vorgeschichte erfasst',
    'fr': 'Aucun autre antécédent enregistré',
  },
  'Un profesional te atiende en tu casa. El pago es en línea al reservar.': {
    'en': 'A professional sees you at home. Payment is online when booking.',
    'de': 'Eine Fachperson behandelt Sie zu Hause. Die Zahlung erfolgt online bei der Buchung.',
    'fr': 'Un professionnel vous soigne chez vous. Le paiement se fait en ligne à la réservation.',
  },
  'atención a domicilio': {
    'en': 'home visits',
    'de': 'Hausbesuche',
    'fr': 'soins à domicile',
  },
  'Reserva tu hora en uno de nuestros centros.': {
    'en': 'Book your appointment at one of our centers.',
    'de': 'Buchen Sie Ihren Termin in einem unserer Zentren.',
    'fr': 'Réservez votre rendez-vous dans l\'un de nos centres.',
  },
  'atención presencial': {
    'en': 'in-person care',
    'de': 'Behandlung vor Ort',
    'fr': 'consultation en présentiel',
  },
  'Consulta por videollamada a la hora que elijas.': {
    'en': 'Video call consultation at the time you choose.',
    'de': 'Sprechstunde per Videoanruf zur gewünschten Uhrzeit.',
    'fr': 'Consultation par appel vidéo à l\'heure de votre choix.',
  },
  'Sin hora: envías tus fotos, pagas en línea y un dermatólogo te responde por correo.': {
    'en': 'No appointment: you send your photos, pay online and a dermatologist answers by email.',
    'de': 'Ohne Termin: Sie senden Ihre Fotos, zahlen online und ein Dermatologe antwortet per E-Mail.',
    'fr': 'Sans rendez-vous : vous envoyez vos photos, payez en ligne et un dermatologue vous répond par e-mail.',
  },
  'dermatología online': {
    'en': 'online dermatology',
    'de': 'Online-Dermatologie',
    'fr': 'dermatologie en ligne',
  },
  'Traumatología': {
    'en': 'Orthopedics',
    'de': 'Orthopädie',
    'fr': 'Orthopédie',
  },
  'Dermatología': {
    'en': 'Dermatology',
    'de': 'Dermatologie',
    'fr': 'Dermatologie',
  },
  'Odontología': {
    'en': 'Dentistry',
    'de': 'Zahnmedizin',
    'fr': 'Dentisterie',
  },
  'Kinesiología': {
    'en': 'Physiotherapy',
    'de': 'Physiotherapie',
    'fr': 'Kinésithérapie',
  },
  'Psicología': {
    'en': 'Psychology',
    'de': 'Psychologie',
    'fr': 'Psychologie',
  },
  'Enfermería': {
    'en': 'Nursing',
    'de': 'Pflege',
    'fr': 'Soins infirmiers',
  },
  '¿En qué idioma quieres usar MiSalud?': {
    'en': 'Which language do you want to use MiSalud in?',
    'de': 'In welcher Sprache möchten Sie MiSalud verwenden?',
    'fr': 'Dans quelle langue voulez-vous utiliser MiSalud ?',
  },
  'Elige el idioma del país donde vives y te atiendes. Tu ficha se muestra en el idioma en que la escribieron tus médicos.': {
    'en': 'Choose the language of the country where you live and receive care. Your record is shown in the language your doctors wrote it in.',
    'de': 'Wählen Sie die Sprache des Landes, in dem Sie leben und behandelt werden. Ihre Akte wird in der Sprache angezeigt, in der Ihre Ärzte sie geschrieben haben.',
    'fr': 'Choisissez la langue du pays où vous vivez et êtes soigné. Votre dossier s\'affiche dans la langue dans laquelle vos médecins l\'ont rédigé.',
  },
  'Continuar': {
    'en': 'Continue',
    'de': 'Weiter',
    'fr': 'Continuer',
  },
  'Al menos {0} caracteres': {
    'en': 'At least {0} characters',
    'de': 'Mindestens {0} Zeichen',
    'fr': 'Au moins {0} caractères',
  },
  'Una mayúscula': {
    'en': 'One uppercase letter',
    'de': 'Ein Großbuchstabe',
    'fr': 'Une majuscule',
  },
  'Una minúscula': {
    'en': 'One lowercase letter',
    'de': 'Ein Kleinbuchstabe',
    'fr': 'Une minuscule',
  },
  'Un número': {
    'en': 'One number',
    'de': 'Eine Zahl',
    'fr': 'Un chiffre',
  },
  'Un carácter especial (! @ # \$ % …)': {
    'en': 'One special character (! @ # \$ % …)',
    'de': 'Ein Sonderzeichen (! @ # \$ % …)',
    'fr': 'Un caractère spécial (! @ # \$ % …)',
  },
  'No es una clave común ni contiene tu RUT o nombre': {
    'en': 'Not a common password and doesn\'t contain your RUT or name',
    'de': 'Kein gängiges Passwort und enthält weder Ihre RUT noch Ihren Namen',
    'fr': 'Pas un mot de passe courant et ne contient ni votre RUT ni votre nom',
  },
  'Tu clave se cambió. Entra con tu clave nueva.': {
    'en': 'Your password was changed. Sign in with your new password.',
    'de': 'Ihr Passwort wurde geändert. Melden Sie sich mit Ihrem neuen Passwort an.',
    'fr': 'Votre mot de passe a été modifié. Connectez-vous avec votre nouveau mot de passe.',
  },
  'Ver clave': {
    'en': 'Show password',
    'de': 'Passwort anzeigen',
    'fr': 'Afficher le mot de passe',
  },
  'Ocultar clave': {
    'en': 'Hide password',
    'de': 'Passwort verbergen',
    'fr': 'Masquer le mot de passe',
  },
  'Muy débil': {
    'en': 'Very weak',
    'de': 'Sehr schwach',
    'fr': 'Très faible',
  },
  'Débil': {
    'en': 'Weak',
    'de': 'Schwach',
    'fr': 'Faible',
  },
  'Regular': {
    'en': 'Fair',
    'de': 'Mittel',
    'fr': 'Moyen',
  },
  'Buena': {
    'en': 'Good',
    'de': 'Gut',
    'fr': 'Bon',
  },
  'Segura': {
    'en': 'Strong',
    'de': 'Sicher',
    'fr': 'Sûr',
  },
  'Cambia tu clave': {
    'en': 'Change your password',
    'de': 'Ändern Sie Ihr Passwort',
    'fr': 'Changez votre mot de passe',
  },
  'Por tu seguridad, tu clave actual ya no cumple las reglas de clave segura. Crea una nueva para seguir.': {
    'en': 'For your security, your current password no longer meets the secure password rules. Create a new one to continue.',
    'de': 'Zu Ihrer Sicherheit erfüllt Ihr aktuelles Passwort die Regeln für sichere Passwörter nicht mehr. Erstellen Sie ein neues, um fortzufahren.',
    'fr': 'Pour votre sécurité, votre mot de passe actuel ne respecte plus les règles de mot de passe sécurisé. Créez-en un nouveau pour continuer.',
  },
  'Contraseña nueva': {
    'en': 'New password',
    'de': 'Neues Passwort',
    'fr': 'Nouveau mot de passe',
  },
  'Repite la contraseña': {
    'en': 'Repeat the password',
    'de': 'Passwort wiederholen',
    'fr': 'Répétez le mot de passe',
  },
  '✓ Las contraseñas coinciden': {
    'en': '✓ Passwords match',
    'de': '✓ Die Passwörter stimmen überein',
    'fr': '✓ Les mots de passe correspondent',
  },
  'Las contraseñas no coinciden': {
    'en': 'Passwords do not match',
    'de': 'Die Passwörter stimmen nicht überein',
    'fr': 'Les mots de passe ne correspondent pas',
  },
  'La clave nueva debe ser distinta de la actual.': {
    'en': 'The new password must be different from the current one.',
    'de': 'Das neue Passwort muss sich vom aktuellen unterscheiden.',
    'fr': 'Le nouveau mot de passe doit être différent de l\'actuel.',
  },
  'Cambiar clave': {
    'en': 'Change password',
    'de': 'Passwort ändern',
    'fr': 'Changer le mot de passe',
  },
  'Compartir tu ficha con el médico': {
    'en': 'Share your record with the doctor',
    'de': 'Ihre Akte mit dem Arzt teilen',
    'fr': 'Partager votre dossier avec le médecin',
  },
  'Voy a mostrar mi ficha clínica a un profesional de la salud. Lo hago por mi propia decisión y bajo mi responsabilidad. Sé que su identidad se verificará en el RNPI y que su nota no entrará a mi ficha hasta esa verificación.': {
    'en': 'I am going to show my medical record to a health professional. I do so by my own decision and under my responsibility. I know their identity will be verified in the RNPI and that their note will not enter my record until that verification.',
    'de': 'Ich zeige meine Krankenakte einer medizinischen Fachkraft. Ich tue dies aus eigener Entscheidung und auf eigene Verantwortung. Ich weiß, dass ihre Identität im RNPI überprüft wird und ihre Notiz erst nach dieser Prüfung in meine Akte aufgenommen wird.',
    'fr': 'Je vais montrer mon dossier médical à un professionnel de santé. Je le fais de ma propre décision et sous ma responsabilité. Je sais que son identité sera vérifiée dans le RNPI et que sa note n\'entrera pas dans mon dossier avant cette vérification.',
  },
  'Voy a mostrar la ficha clínica de la persona que cuido a un profesional de la salud, bajo mi responsabilidad como su cuidador. Sé que su identidad se verificará en el RNPI y que su nota no entrará a la ficha hasta esa verificación.': {
    'en': 'I am going to show the medical record of the person I care for to a health professional, under my responsibility as their caregiver. I know their identity will be verified in the RNPI and that their note will not enter the record until that verification.',
    'de': 'Ich zeige die Krankenakte der von mir betreuten Person einer medizinischen Fachkraft, unter meiner Verantwortung als Betreuer. Ich weiß, dass ihre Identität im RNPI überprüft wird und ihre Notiz erst nach dieser Prüfung in die Akte aufgenommen wird.',
    'fr': 'Je vais montrer le dossier médical de la personne dont je m\'occupe à un professionnel de santé, sous ma responsabilité d\'aidant. Je sais que son identité sera vérifiée dans le RNPI et que sa note n\'entrera pas dans le dossier avant cette vérification.',
  },
  'Confirmar con huella': {
    'en': 'Confirm with fingerprint',
    'de': 'Mit Fingerabdruck bestätigen',
    'fr': 'Confirmer avec l\'empreinte',
  },
  'Acerque su teléfono al lector del médico': {
    'en': 'Bring your phone close to the doctor\'s reader',
    'de': 'Halten Sie Ihr Telefon an das Lesegerät des Arztes',
    'fr': 'Approchez votre téléphone du lecteur du médecin',
  },
  'Mantén el teléfono cerca, con el Bluetooth encendido.': {
    'en': 'Keep the phone close, with Bluetooth on.',
    'de': 'Halten Sie das Telefon in der Nähe, mit eingeschaltetem Bluetooth.',
    'fr': 'Gardez le téléphone à proximité, avec le Bluetooth activé.',
  },
  'Muestre este código al médico': {
    'en': 'Show this code to the doctor',
    'de': 'Zeigen Sie diesen Code dem Arzt',
    'fr': 'Montrez ce code au médecin',
  },
  'El médico lo escanea con la cámara de su teléfono. Sirve una sola vez.': {
    'en': 'The doctor scans it with their phone camera. It works only once.',
    'de': 'Der Arzt scannt ihn mit der Kamera seines Telefons. Er gilt nur einmal.',
    'fr': 'Le médecin le scanne avec l\'appareil photo de son téléphone. Il ne sert qu\'une fois.',
  },
  'Si el médico tiene el Lector HypokratIA, se conectará solo.': {
    'en': 'If the doctor has the HypokratIA Reader, it will connect automatically.',
    'de': 'Wenn der Arzt das HypokratIA-Lesegerät hat, verbindet es sich automatisch.',
    'fr': 'Si le médecin a le Lecteur HypokratIA, il se connectera automatiquement.',
  },
  '¿El médico no puede escanear? Enviar por email': {
    'en': 'Can\'t the doctor scan it? Send by email',
    'de': 'Kann der Arzt nicht scannen? Per E-Mail senden',
    'fr': 'Le médecin ne peut pas scanner ? Envoyer par e-mail',
  },
  'No hay un lector cerca ni internet': {
    'en': 'No reader nearby and no internet',
    'de': 'Kein Lesegerät in der Nähe und kein Internet',
    'fr': 'Aucun lecteur à proximité ni internet',
  },
  'Con el Lector HypokratIA el médico puede ver tu ficha aunque no haya internet. Pregúntale si tiene uno o acerca el teléfono a su lector.': {
    'en': 'With the HypokratIA Reader the doctor can see your record even without internet. Ask if they have one, or bring your phone close to their reader.',
    'de': 'Mit dem HypokratIA-Lesegerät kann der Arzt Ihre Akte auch ohne Internet sehen. Fragen Sie, ob er eines hat, oder halten Sie Ihr Telefon an sein Lesegerät.',
    'fr': 'Avec le Lecteur HypokratIA, le médecin peut voir votre dossier même sans internet. Demandez-lui s\'il en a un ou approchez votre téléphone de son lecteur.',
  },
  'Sigo buscando el lector…': {
    'en': 'Still looking for the reader…',
    'de': 'Suche weiter nach dem Lesegerät…',
    'fr': 'Je cherche toujours le lecteur…',
  },
  'No se encontró el lector del médico': {
    'en': 'The doctor\'s reader was not found',
    'de': 'Das Lesegerät des Arztes wurde nicht gefunden',
    'fr': 'Le lecteur du médecin est introuvable',
  },
  'Verifica que el Lector HypokratIA esté enchufado al computador y que el Bluetooth del teléfono esté encendido.': {
    'en': 'Check that the HypokratIA Reader is plugged into the computer and that the phone\'s Bluetooth is on.',
    'de': 'Prüfen Sie, ob das HypokratIA-Lesegerät am Computer angeschlossen und Bluetooth am Telefon eingeschaltet ist.',
    'fr': 'Vérifiez que le Lecteur HypokratIA est branché à l\'ordinateur et que le Bluetooth du téléphone est activé.',
  },
  'Registrado en la Superintendencia de Salud (RNPI)': {
    'en': 'Registered with the Chilean Health Superintendency (RNPI)',
    'de': 'Bei der chilenischen Gesundheitsaufsicht registriert (RNPI)',
    'fr': 'Inscrit auprès de la Surintendance de la santé du Chili (RNPI)',
  },
  'No aparece en el RNPI. Su nota quedará en revisión.': {
    'en': 'Not found in the RNPI. Their note will be reviewed.',
    'de': 'Nicht im RNPI gefunden. Die Notiz wird geprüft.',
    'fr': 'Introuvable dans le RNPI. Sa note sera examinée.',
  },
  'Se verificará en el RNPI cuando vuelva internet.': {
    'en': 'Will be verified in the RNPI when internet returns.',
    'de': 'Wird im RNPI geprüft, sobald wieder Internet verfügbar ist.',
    'fr': 'Sera vérifié dans le RNPI au retour d\'internet.',
  },
  'El RNPI no respondió. Se verificará más tarde.': {
    'en': 'The RNPI did not respond. It will be verified later.',
    'de': 'Das RNPI hat nicht geantwortet. Es wird später geprüft.',
    'fr': 'Le RNPI n\'a pas répondu. La vérification se fera plus tard.',
  },
  'Verificando en el RNPI…': {
    'en': 'Checking the RNPI…',
    'de': 'Wird im RNPI geprüft…',
    'fr': 'Vérification dans le RNPI…',
  },
  'Especialidad': {
    'en': 'Specialty',
    'de': 'Fachgebiet',
    'fr': 'Spécialité',
  },
  'CERTIFICADO': {
    'en': 'CERTIFIED',
    'de': 'ZERTIFIZIERT',
    'fr': 'CERTIFIÉ',
  },
  'NO REGISTRADO': {
    'en': 'NOT REGISTERED',
    'de': 'NICHT REGISTRIERT',
    'fr': 'NON INSCRIT',
  },
  'Profesional de la salud': {
    'en': 'Health professional',
    'de': 'Gesundheitsfachperson',
    'fr': 'Professionnel de santé',
  },
  'Superintendencia de Salud · Registro Nacional de Prestadores': {
    'en': 'Chilean Health Superintendency · National Provider Registry',
    'de': 'Chilenische Gesundheitsaufsicht · Nationales Register',
    'fr': 'Surintendance de la santé du Chili · Registre national',
  },
  'Verificado': {
    'en': 'Verified',
    'de': 'Verifiziert',
    'fr': 'Vérifié',
  },
  'No registrado': {
    'en': 'Not registered',
    'de': 'Nicht registriert',
    'fr': 'Non inscrit',
  },
  'Pendiente': {
    'en': 'Pending',
    'de': 'Ausstehend',
    'fr': 'En attente',
  },
};
