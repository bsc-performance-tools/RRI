/*  RRI - Relevant Routine Identifier
*  Copyright (C) 2016  Damien Dosimont
*  
*  This file is part of RRI.
*  
*  RRI is free software: you can redistribute it and/or modify
*  it under the terms of the GNU General Public License as published by
*  the Free Software Foundation, either version 3 of the License, or
*  (at your option) any later version.
*  
*  This program is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*  
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef DUMMYSTREAMREADER_H
#define DUMMYSTREAMREADER_H

#include <QTextStream>
#include <QChar>
#include "core_constants.h"

class DummyStreamReader
{
public:
    DummyStreamReader(QTextStream *stream);
    DummyStreamReader();
    DummyStreamReader(QTextStream *stream, QChar separator);
    DummyStreamReader(QChar separator);

    QChar getSeparator() const;
    void setSeparator(const QChar &value);

    QStringList readline();
    bool isEnd();

    QTextStream *getStream() const;
    void setStream(QTextStream *value);

private:
    QTextStream *stream;
    QChar separator;
    QString line;
};

#endif // DUMMYSTREAMREADER_H
