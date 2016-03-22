/*  RRI - Relevant Routine Identifier
*   Copyright (C) 2016  Damien Dosimont
*
*   This file is part of RRI.
*
*   RRI is free software: you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation, either version 3 of the License, or
*   (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <iostream>
#include <math.h>

#include <QString>
#include <QTextStream>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QVector>
#include <QDebug>

#include <rricore.h>
#include <part.h>
#include <prvregionwriter.h>

#include "argumentmanager.h"
#include "filemanager.h"
#include "bin_constants.h"

int main(int argc, char *argv[])
{
    int error;
    ArgumentManager* argumentManager = new ArgumentManager(argc, argv);
    if (!argumentManager->getConform()||argumentManager->getHelp()){
        argumentManager->printUsage();
        return RETURN_ERR_CMD;
    }
    FileManager* fileManager = new FileManager(argumentManager);
    error=fileManager->init();
    if (error!=RETURN_OK){
        delete fileManager;
        delete argumentManager;
        qCritical()<<"Exiting";
        return RETURN_ERR_OTHER;
    }
    PrvRegionWriter* regionWriter=new PrvRegionWriter();
    if (!argumentManager->getUniqueFile()){
        regionWriter->setInputPrvFile(fileManager->getInputPrvFiles());
        regionWriter->setOutputPrvFile(fileManager->getOutputPrvFiles());
        regionWriter->parseRegions(fileManager->getRegionStream());
        regionWriter->setEventTypeBlockItems();
        regionWriter->pushRRIRegionHeader();
    }
    RRICore* core;
    for (int i=0; i<fileManager->getIterationNames().size(); i++){
        qDebug().nospace()<<"Iteration "<<i+1<<", session: "<<fileManager->getIterationNames()[i];
        qDebug().nospace()<<"Input file: "<<fileManager->getStreamSets()[i]->getInputFile()->fileName();
        core = new RRICore();
        core->getParameters()->setAnalysisType(rri::RRI);
        core->getParameters()->setStream(fileManager->getStreamSets()[i]->getInputStream());
        core->getParameters()->setTimesliceNumber(argumentManager->getTimeSliceNumber());
        core->getParameters()->setThreshold(argumentManager->getThreshold());
        core->getParameters()->setMinprop(argumentManager->getMinprop());
        if (!core->buildMicroscopicModel()){
            return 4;
        }
        core->buildMacroscopicModels();
        /*int timesliceNumber=argumentManager->getTimeSliceNumber();
        while(argumentManager->getNovoid()&&core->hasVoid()&&timesliceNumber>MIN_TSNUMBER_NOVOID){
            timesliceNumber/=2;
            qDebug().nospace()<<"Empty timeslice has been found. Changing timeslice number to "<<timesliceNumber;
            core->getParameters()->setTimesliceNumber(timesliceNumber);
            if (!core->buildMicroscopicModel()){
                return 4;
            }
            core->buildMacroscopicModels();
        }
        if (argumentManager->getNovoid()&&core->hasVoid()){
            qDebug().nospace()<<"Failed!";
            core->getParameters()->setTimesliceNumber(argumentManager->getTimeSliceNumber());
            if (!core->buildMicroscopicModel()){
                return 4;
            }
            core->buildMacroscopicModels();
        }else{
            qDebug().nospace()<<"Success!";
        }*/
        QTextStream* qualityStream=fileManager->getStreamSets()[i]->getQualityStream();
        QTextStream* partitionStream=fileManager->getStreamSets()[i]->getPartitionStream();
        QTextStream* detailStream=fileManager->getStreamSets()[i]->getDetailStream();
        QTextStream* routineStream=fileManager->getStreamSets()[i]->getRoutineStream();
        QTextStream* infoStream=fileManager->getStreamSets()[i]->getInfoStream();
        for (int i=0; i<core->getMacroscopicModel()->getPs().size(); i++){
            if (std::isnan(core->getMacroscopicModel()->getQualities()[i]->getGain())||std::isnan(core->getMacroscopicModel()->getQualities()[i]->getLoss())){
                std::cerr<<"NaN value detected, stopping the rendering"<<std::endl;
                return 5;
            }
            *qualityStream<<core->getMacroscopicModel()->getPs()[i]<<SEP
                           <<core->getMacroscopicModel()->getQualities()[i]->getGain()<<SEP
                           <<core->getMacroscopicModel()->getQualities()[i]->getLoss()
                           <<endl;
            core->getParameters()->setP(core->getMacroscopicModel()->getPs()[i]);
            core->selectMacroscopicModel();
            core->buildRedistributedModel();
            QVector<Part*> parts=core->getParts();
            for (int j=0; j< parts.size(); j++){
                *partitionStream<<core->getMacroscopicModel()->getPs()[i]<<SEP<<parts[j]->getFirstRelative()<<SEP<<parts[j]->getLastRelative()<<SEP<<core->getRedistributedModel()->getPartsAsString()[j]<<endl;
                RRIPart* rriPart=dynamic_cast<RRIRedistributedModel*>(core->getRedistributedModel())->getRRIParts()[j];
                if (rriPart->getRoutines().size()==0){
                    *detailStream<<core->getMacroscopicModel()->getPs()[i]<<SEP<<parts[j]->getFirstRelative()<<SEP<<
                                    parts[j]->getLastRelative()<<SEP<<"void"<<SEP<<0<<SEP<<
                                    0<<SEP<<0<<endl;
                }else{
                    QList<RRIRoutineInfo*> routines=rriPart->getRoutines().values();
                    for (RRIRoutineInfo* routine:routines){
                            *detailStream<<core->getMacroscopicModel()->getPs()[i]<<SEP<<parts[j]->getFirstRelative()<<SEP<<
                                            parts[j]->getLastRelative()<<SEP<<routine->toString()<<SEP<<routine->getPercentageDuration()<<SEP<<
                                            routine->getAverageCallStackLevel()<<SEP<<(routine->getIndex()==core->getRedistributedModel()->getPartsAsIndex()[j])<<endl;
                    }
                }
            }
            QVector<RRIObject*> codelines=dynamic_cast<RRIRedistributedModel*>(core->getRedistributedModel())->generateCodelines();
            for (int j=0; j< codelines.size(); j++){
                *routineStream<<core->getMacroscopicModel()->getPs()[i]<<SEP
                      <<codelines[j]->getTsPercentage()<<SEP
                      <<codelines[j]->getCodeline()
                      <<endl;
            }

        }
        *infoStream<<"Overall aggregation score (negative: possible issue, 0: bad, 100: good) = "<<core->getMacroscopicModel()->getAggregationScore()<<endl;
        core->setP(rri::NORM_INFLECT);
        core->selectMacroscopicModel();
        core->buildRedistributedModel();
        *infoStream<<"Global inflection point: p = "<<core->getCurrentP()<<endl;
        core->setP(rri::NORM_INFLECT2);
        core->selectMacroscopicModel();
        core->buildRedistributedModel();
        *infoStream<<"Local inflection point: p = "<<core->getCurrentP()<<endl;
        *infoStream<<"Time slice number = "<<core->getParameters()->getTimesliceNumber()<<endl;
        if (!argumentManager->getUniqueFile()){
            regionWriter->pushRRIRegion(fileManager->getIterationNames()[i], core);
        }
        fileManager->getStreamSets()[i]->close();
        delete core;
    }
    if (!argumentManager->getUniqueFile()){
        regionWriter->pushRRIEventTypeBlock();
    }
    delete fileManager;
    delete regionWriter;
    delete argumentManager;
    qDebug().nospace()<<"Exiting";
    return RETURN_OK;
}
