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

#ifndef ApplicationUI_HPP_
#define ApplicationUI_HPP_

#include <QObject>
#include <bb/cascades/InvokeQuery>
#include <bb/cascades/Invocation>
#include <QTimer>
#include <bb/platform/bbm/Context>
#include <bb/platform/bbm/RegistrationState>
namespace bb
{
    namespace cascades
    {
        class LocaleHandler;
    }
}

class QTranslator;
#include "AppSettings.hpp"
#include "pgaudio_js.hpp"

/*!
 * @brief Application UI object
 *
 * Use this object to create and init app UI, to create context objects, to register the new meta types etc.
 */
class ApplicationUI: public QObject
{
    Q_OBJECT
public:
    ApplicationUI();
    ~ApplicationUI();
    //QString appid="50976889";
    Q_INVOKABLE QString getValue(const QString &key,const QString &def);
    Q_INVOKABLE void setValue(const QString &key,const QString &value);
    Q_INVOKABLE QString getLang();
    Q_INVOKABLE void shareFile(QString fileName);
    Q_INVOKABLE void requestScreenshot();
    Q_INVOKABLE void registerBBM();
    Q_INVOKABLE QString readTextFile(QString filepath);
    Q_INVOKABLE void deleteFile(QString filepath);
    Q_INVOKABLE bool writeTextFile(QString filepath, QString filecontent);
    Q_INVOKABLE void play(QString type);

private slots:
    Q_SLOT void onSystemLanguageChanged();
    Q_SLOT void onArmed();
    Q_SLOT void takeshot();
    Q_SLOT void onBBMregUpdated(bb::platform::bbm::RegistrationState::Type c);
private:
    QTranslator* m_pTranslator;
    int dwidth;
    int dheight;
    bb::cascades::LocaleHandler* m_pLocaleHandler;
    bb::cascades::Invocation* invocation;
    bb::platform::bbm::Context *bbmcontext;
    PGaudio *pga;
    bool inited;
    void initAudio();
    bool audioInited;
Q_SIGNALS:
    void timeout();
    void bbmComplete(int status);
};

#endif /* ApplicationUI_HPP_ */
