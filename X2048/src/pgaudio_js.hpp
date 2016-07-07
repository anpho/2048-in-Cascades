#include <string>
#include <qstring.h>
#include <qhash.h>
#include <AL/al.h>
#include <AL/alc.h>
#include <AL/alut.h>

#ifndef PGAUDIO_JS_H_
#define PGAUDIO_JS_H_

class PGaudio
{
public:
    PGaudio();
    ~PGaudio();
    std::string preload(QString path, QString name, int voices);
    std::string unload(QString name);
    std::string stop(QString name);
    float getDuration(QString name);
    std::string play(QString filename);
    std::string loop(QString filename);
    bool CanDelete();
private:
    QHash<QString, ALuint> m_soundBuffersHash;
    QHash<QString, ALuint> m_sourceIndexHash;
};

#endif /* PGAUDIO_JS_HPP_ */
