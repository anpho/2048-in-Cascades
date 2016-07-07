/*
 * Copyright (c) 2011-2014 BlackBerry Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "applicationui.hpp"

#include <bb/cascades/Application>
#include <bb/cascades/QmlDocument>
#include <bb/cascades/AbstractPane>
#include <bb/cascades/LocaleHandler>
#include <bb/device/DisplayInfo>
#include <bb/system/Screenshot>
#include <bb/platform/bbm/Context>
#include <bb/platform/bbm/RegistrationState>
#include <bb/platform/bbm/UserProfile>
#include <bb/cascades/controls/container.h>
#include <bb/cascades/SceneCover>
#include <string>
using namespace bb::cascades;
using namespace bb::platform::bbm;
using namespace bb::system;

ApplicationUI::~ApplicationUI()
{
    if (audioInited) {
        delete pga;
    }
}

ApplicationUI::ApplicationUI() :
        QObject()
{
    // OpenAL Audio
    audioInited = false;
    if (getValue("sound", "false").compare("true") == 0) {
        // Why?
        // Because initAudio will open the audio tunnel and make a white noise in speaker,
        // which will drain the battery of bluetooth-earphone.
        // So I'd prefer to init this feature as load-on-request.
        initAudio();
    }
    // OpenAL Audio

    inited = false;
    // prepare the localization
    m_pTranslator = new QTranslator(this);
    m_pLocaleHandler = new LocaleHandler(this);

    bool res = QObject::connect(m_pLocaleHandler, SIGNAL(systemLanguageChanged()), this,
            SLOT(onSystemLanguageChanged()));
    // This is only available in Debug builds
    Q_ASSERT(res);
// Since the variable is not used in the app, this is added to avoid a
// compiler warning
    Q_UNUSED(res);

// initial load
    onSystemLanguageChanged();

// Create scene document from main.qml asset, the parent is set
// to ensure the document gets destroyed properly at shut down.
    QmlDocument *qml = QmlDocument::create("asset:///main.qml").parent(this);
    qml->setContextProperty("_app", this);

    // Screen Height and Width
    bb::device::DisplayInfo display;
    dwidth = display.pixelSize().width();
    dheight = display.pixelSize().height();

    QDeclarativePropertyMap* displayProperties = new QDeclarativePropertyMap;
    displayProperties->insert("width", QVariant(dwidth));
    displayProperties->insert("height", QVariant(dheight));

    qml->setContextProperty("DisplayInfo", displayProperties);

// Create root object for the UI
    AbstractPane *root = qml->createRootObject<AbstractPane>();
// Set created root object as the application scene
    Application::instance()->setScene(root);


}
void ApplicationUI::initAudio()
{

    if (audioInited)
        return;
    qDebug() << "[PGA]initAudio";
    pga = new PGaudio();
    audioInited = true;

    qDebug() << (pga->preload("assets/2048/sounds/", "low.wav", 1)).c_str();
    qDebug() << (pga->preload("assets/2048/sounds/", "high.wav", 1)).c_str();
    qDebug() << (pga->preload("assets/2048/sounds/", "win.wav", 1)).c_str();
    qDebug() << "[PGA]Audio inited.";
}
void ApplicationUI::play(QString type)
{
    initAudio();
    qDebug() << "[PGA]Playing: " + type;
    pga->play(type + ".wav");
}

void ApplicationUI::onSystemLanguageChanged()
{
    QCoreApplication::instance()->removeTranslator(m_pTranslator);
// Initiate, load and install the application translation files.
    QString locale_string = getLang();
    QString file_name = QString("X2048_%1").arg(locale_string);
    if (m_pTranslator->load(file_name, "app/native/qm")) {
        QCoreApplication::instance()->installTranslator(m_pTranslator);
    }
}

QString ApplicationUI::getValue(const QString &key, const QString &def)
{
    return AppSettings::getValueFor(key, def);
}
void ApplicationUI::setValue(const QString &key, const QString &value)
{
    AppSettings::saveValueFor(key, value);
    if (key.compare("lang") == 0) {
        onSystemLanguageChanged();
    }
}
QString ApplicationUI::getLang()
{
    return getValue("lang", QLocale().name());
}

void ApplicationUI::shareFile(QString fileName)
{
    if (!fileName.startsWith("file://")) {
        fileName = fileName.prepend("file://");
    }

    invocation = Invocation::create(InvokeQuery::create().parent(this).uri(fileName));

    connect(invocation, SIGNAL(armed()), this, SLOT(onArmed()));
    connect(invocation, SIGNAL(finished()), invocation, SLOT(deleteLater()));

}

void ApplicationUI::onArmed()
{
    invocation->trigger("bb.action.SHARE");
}

void ApplicationUI::requestScreenshot()
{
    QTimer().singleShot(334, this, SLOT(takeshot()));
}

void ApplicationUI::takeshot()
{
    emit timeout();
}

void ApplicationUI::registerBBM()
{
    if (getValue("ppid", "").length() > 0) {
        emit bbmComplete(0);
        return;
    }
    if (!inited) {

        bbmcontext = new Context("d4a0327f-c94e-4471-a6b9-c59cff90c5d7", this);
        connect(bbmcontext,
                SIGNAL(registrationStateUpdated(bb::platform::bbm::RegistrationState::Type)), this,
                SLOT(onBBMregUpdated(bb::platform::bbm::RegistrationState::Type)));
        inited = true;
    }
    qDebug() << "[BBM] STATE: " << bbmcontext->registrationState();
    if (bbmcontext->registrationState() == RegistrationState::BlockedByUser) {
        emit bbmComplete(1);
    } else {
        bbmcontext->requestRegisterApplicationSilent();
    }
}

void ApplicationUI::onBBMregUpdated(bb::platform::bbm::RegistrationState::Type c)
{
    if (c == RegistrationState::Allowed) {
        bb::platform::bbm::UserProfile profile(bbmcontext);
        setValue("ppid", profile.ppId());
        qDebug() << "[BBM]Allowed.";
        emit bbmComplete(0);
    } else if (c == RegistrationState::Pending) {
        emit bbmComplete(-1);
        qDebug() << "[BBM]Pending...";
    } else if (c == RegistrationState::Unregistered) {
        bbmcontext->requestRegisterApplicationSilent();
        qDebug() << "[BBM]Not registered, register app.";
    } else if (c == RegistrationState::BbmDisabled) {
        qDebug() << "[BBM]BBM disabled.";
    } else {
        emit bbmComplete(1);
        qDebug() << "[BBM]ERROR: " + c;
    }
}

QString ApplicationUI::readTextFile(QString filepath)
{
    QFile file(filepath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return "";
    QString c = "";
    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine();
        c.append(line).append("\r\n");
    }
    return c;
}
void ApplicationUI::deleteFile(QString filepath)
{
    QFile file(filepath);
    if (file.exists()) {
        file.remove();
    }
}

bool ApplicationUI::writeTextFile(QString filepath, QString filecontent)
{
    QFile textfile(filepath);
    if (textfile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&textfile);
        out << filecontent;
        textfile.close();
        return (true);
    } else {
        return (false);
    }

}
