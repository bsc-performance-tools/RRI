#   RRI - Relevant Routine Identifier
#   Copyright (C) 2016  Damien Dosimont
#
#   This file is part of RRI.
#
#   RRI is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.


library(ggplot2)
library(RColorBrewer)
library(gridExtra)
library(digest)
#Sys.setlocale("LC_MESSAGES", 'en_US')

#"Static" variables

info_input_file="info.csv"
parts_input_file="partitions.csv"
qualities_input_file="qualities.csv"
details_input_file="detailed_partition.csv"
codelines_input_file="routines.csv"
parts_output_basename="parts"
qualities_output_file="qualities.pdf"
qualities2_output_file="qualities2.pdf"
cheader_info<-c("SCORE", "INFLEX", "INFLEX2", "BEST", "TS")
cheader_parts<-c("P", "START", "END", "Function")
cheader_details<-c("P", "START", "END", "Function", "Ratio", "Callstack", "SELECTED")
cheader_codelines<-c("P", "TS", "Codeline")
cheader_qualities<-c("P", "GAIN", "LOSS")
cheader_dump<-c("TYPE", "INSTANCE", "GROUP", "TS", "COUNTER", "VALUE")
cheader_interpolate<-c("INSTANCE", "GROUP", "COUNTER", "TS", "VALUE")
cheader_slope<-c("INSTANCE", "GROUP", "COUNTER", "TS", "VALUE", "CUMUL")

labelmax=22
ulabelmax=33

#function to read a csv file
read <- function(file, cheader, sep=',') {
  df <- read.csv(file, header=FALSE, sep = sep, strip.white=TRUE)
  names(df) <- cheader
  df
}

#function to generate a vector containing all the p
make_plist <- function(data){
  plist<-data[["P"]]
  plist<-unique(plist)
  plist
}

#function to generate a vector containing all the counters
make_counterlist <- function(data){
  counterlist<-data[["COUNTER"]]
  counterlist<-unique(counterlist)
  counterlist
}

#from a string, generate a color using a hash
string2color<- function(string){
  digested=digest(as.character(string), serialize=FALSE)
  r=substr(digested,1,2)
  g=substr(digested,3,4)
  b=substr(digested,5,6)
  h<-paste(r,g,b,sep="")
  if ((r>215&g>215&b>215)|(r<30&g<30&b<30)){
    h = string2color(paste(string,":-o",sep=""))
  }
  h
}

#wrapper for string2color
color_generator <- function(stringlist, aggString=c("")){
  sorted<-sort(stringlist)
  hashcoded<-rep(0, length(stringlist))
  for (i in 1:length(sorted)){
    if (sorted[i]==aggString){
      hashcoded[i]=0
    }
    else{
      hashcoded[i]=string2color(sorted[i])
    }
  }
  hexed<-format(as.hexmode(hashcoded),width=6)
  color=paste("#",hexed,sep="")
  names(color)=sorted
  color
}

#not really usefull: other way of computing interest point
inflex_p <- function(data){
  dtemp<-data
  dtemp$LOSSCOR<-dtemp$LOSS-dtemp$GAIN
  dtemp<-dtemp[(dtemp$P >0),]
  i<-which.min(dtemp[,"LOSSCOR"])
  dtemp[i,"P"]
}

#not really usefull: other way of computing interest point
inflex2_p <- function(data){
  dtemp1<-data
  dtemp2<-data
  p<-inflex_p(data)
  dtemp1<-dtemp1[(dtemp1$P %in% p),]
  xfactor<-dtemp1[1,"GAIN"]
  yfactor<-dtemp1[1,"LOSS"]
  if (xfactor>0){
    dtemp2$GAIN<-dtemp2$GAIN/xfactor
  }
  if (yfactor>0){
    dtemp2$LOSS<-dtemp2$LOSS/yfactor
  }
  dtemp2[(dtemp2$P %in% p),"GAIN"]<-1
  dtemp2[(dtemp2$P %in% p),"LOSS"]<-1
  dtemp2<-dtemp2[(dtemp2$P <=p),]
  dtemp2<-dtemp2[(dtemp2$P >0),]
  dtemp2$LOSSCOR<-dtemp2$LOSS-dtemp2$GAIN
  i<-which.min(dtemp2[,"LOSSCOR"])
  dtemp2[i,"P"]
}

#build the quality curves with p in x axis and gain/loss un y axis
print_qualities <- function(data){
  dtemp<-data
  ntemp <- data.frame(P= dtemp[2:(nrow(dtemp)),1]-0.0000001, GAIN= dtemp[1:nrow(dtemp)-1,2], LOSS= dtemp[1:nrow(dtemp)-1,3])
  ntemp[1,]<-c(1,1,1)
  dtemp<-rbind(dtemp, ntemp)
  dtemp<- dtemp[order(dtemp$P),] 
  dtemp$LABELX<-dtemp$P
  dtemp$LABELX[seq(2,nrow(dtemp),2)]<-""
  dtemp$LABELY<- with(dtemp, pmax(GAIN, LOSS))
  xlabel<- "Parameter p"
  ylabel<- "Amplitude (normalized)"
  legend<- "Quality Measures vs Parameter p"
  plot<-ggplot(dtemp, aes(x=P))
  plot<-plot + geom_line(aes(y=GAIN, colour = "Complexity reduction"))
  plot<-plot + geom_line(aes(y=LOSS, colour = "Information loss"))
  plot<-plot + theme_bw()
  plot<-plot + labs(x=xlabel,y=ylabel)
  plot<-plot + scale_colour_manual(name="Quality measures",values = c("green","red"))
  plot
}

#build the quality curves loss vs gain
print_qualities2 <- function(data){
  dtemp<-data
  p<-inflex_p(data)
  p2<-inflex2_p(data)
  dtemp2<-dtemp[(dtemp$P %in% p),]
  dtemp3<-dtemp[(dtemp$P %in% p2),]
  xlabel<- "Complexity reduction"
  ylabel<- "Information loss"
  plot<-ggplot()
  plot<-plot+geom_line(data=dtemp,aes(x=GAIN,y=LOSS), color="black")
  plot<-plot+geom_point(data=dtemp,aes(x=GAIN,y=LOSS), color="black")
  plot<-plot+geom_point(data=dtemp2,aes(x=GAIN,y=LOSS), color="red")
  plot<-plot+geom_point(data=dtemp3,aes(x=GAIN,y=LOSS), color="green")
  plot<-plot + theme_bw()
  plot<-plot + labs(x=xlabel,y=ylabel)
  plot
}

#build the callstack representation
#arg: data, parameter p, jesus:bool no space between time aggregates, aggreg:bool should we aggregate the bottom, filter:float remove routines whose proportion is below this amount, showSelected:bool highlight the selected routine
print_details_aggreg <- function(data, p, jesus, aggreg, filter, showSelected){
#filtering data related with the current p
  dtemp<-data[(data$P %in% p),]
#removing the void routine
  dtemp<-dtemp[!(dtemp$Function %in% "void"),]
#hacking the callstack: reverse the callstack, manage the cases in which we aggregate the callstack bottom
  callstackDepth<-dtemp[which.max(dtemp[,"Callstack"]),"Callstack"]
  aggCallstackDepth<-0
  aggVector=c()
  aggString=c("")
  if (aggreg){
    for (i in callstackDepth:0){
      func<-unique(dtemp[(dtemp$Callstack %in% i),"Function"])
      if (length(func) == 1){
        temp<-dtemp[dtemp$Function %in% func[1],]
        if (length(!(temp$Ratio %in% 1)==0)&length((temp$SELECTED %in% 1)==0)){
          temp$DURATION=temp$END-temp$START
          duration=sum(temp$DURATION)
          if (duration == 1){
            aggCallstackDepth<-callstackDepth-i+1
            aggVector[callstackDepth-i+1]=as.character(func[1])
          }else break
        }else break
      }else break
    }
    if (aggCallstackDepth>=2){
      aggString=paste(aggVector,collapse="+")
      dtemp=dtemp[(dtemp$Callstack<=(callstackDepth-aggCallstackDepth+1)),]
      levels(dtemp$Function) <- c(levels(dtemp$Function), as.character(aggString))
      dtemp$Function[(dtemp$Callstack %in% (callstackDepth-aggCallstackDepth+1))]<-as.character(aggString)
    }
  }
  dtemp<-dtemp[order(dtemp$START, -dtemp$Callstack), ]
  callstackDepth<-dtemp[which.max(dtemp[,"Callstack"]),"Callstack"]
#compute a "priority score" that determines, in case of conflict between two routines at the same callstack level, which one should be below/above
#the first routine appearing over time in the region will be below
  for (i in 0:callstackDepth){
    func<-unique(dtemp[(dtemp$Callstack %in% i),"Function"])
    fv<-seq(1,length(func))
    names(fv)<-func
    dtemp$POSITION[(dtemp$Callstack %in% i)]<-fv[dtemp[(dtemp$Callstack %in% i),"Function"]]
  }
#filtering the routines below a certain amount (variable filter)
  dtemp<-dtemp[dtemp$Ratio >= (filter/100),]
#sorting the data
  dtemp<-dtemp[order(dtemp$START, -dtemp$Callstack, dtemp$POSITION),]
  xlabel<-  paste("Time (relative), p=", p, sep="")
  ylabel<-  paste("Execution time (relative), p=", p, sep="")
  legend<-  paste("Relevant routines, p=", p, sep="")
#computing the graphical position of each routine rectangle
  dtemp$OFFSET<-0
  currentStart<-dtemp[1,"START"]
  currentCallstack<-dtemp[1,"Callstack"]
  offset<-0
  for (i in 2:nrow(dtemp)){
    newStart=dtemp[i,"START"]
    newCallstack=dtemp[i,"Callstack"]
    if (newStart != currentStart){
    currentStart<-newStart
    currentCallstack=newCallstack
    offset<-0
    }else{
      if (newCallstack != currentCallstack){
      currentCallstack=newCallstack
      offset<-callstackDepth-currentCallstack
      }
      else{
      offset<-offset+dtemp[i-1,"Ratio"]
      }
      dtemp[i,"OFFSET"]<-offset
    }
  }
  dtemp<-dtemp[order(dtemp$SELECTED), ]
  dtemp2<-dtemp[(dtemp$SELECTED %in% 1), ]
  dsize=0.3
  plot<-ggplot()
  plot<-plot+scale_x_continuous(name=xlabel, limits =c(0,1))
  func<-unique(dtemp[["Function"]])
  vcolors=color_generator(func, as.character(aggString))
  #managing the case in which we do not have to print the selected routine
  if (!showSelected){
    for (i in 1:nrow(dtemp)){
      for (j in 1:nrow(dtemp)){
        if ((dtemp[i,"END"]!=dtemp[i,"START"])&&(dtemp[i,"END"]!=dtemp[i,"START"])){
          if (((dtemp[i,"Function"])==(dtemp[j,"Function"]))&&((dtemp[i,"Ratio"])==(dtemp[j,"Ratio"]))&&((dtemp[i,"Callstack"])==(dtemp[j,"Callstack"]))){
            if ((dtemp[i,"END"])==(dtemp[j,"START"])){
              dtemp[i,"END"]=dtemp[j,"END"]
              dtemp[j,"START"]=dtemp[j,"END"]
            }
            else if ((dtemp[j,"END"])==(dtemp[i,"START"])){
              dtemp[j,"END"]=dtemp[i,"END"]
              dtemp[i,"START"]=dtemp[i,"END"]
            }
          }
        }
      }
    }
  }
  #Manage the labels for each rectangle: we may need to trucate the label if it's too long, and we print the label for a routine only once, during the first occurence
  dtemp$DURATION<-dtemp$END-dtemp$START
  dtemp<-dtemp[dtemp$DURATION >= 0,]
  dtemp$LABEL=as.character(dtemp$Function)
  dtemp$TLABELtemp=as.character(substr(dtemp$LABEL,1,labelmax))
  dtemp$TLABELtemp=as.character(paste(dtemp$TLABELtemp,"...",sep=""))
  dtemp$TLABEL=as.character(dtemp$Function)
  dtemp[nchar(as.character(dtemp$LABEL))>labelmax,"TLABEL"]=as.character(dtemp[nchar(as.character(dtemp$LABEL))>labelmax, "TLABELtemp"])
  dtemp$ULABELtemp1=as.character(substr(dtemp$LABEL,1,ulabelmax/2-2))
  dtemp$ULABELtemp2=as.character(substr(dtemp$LABEL,nchar(as.character(dtemp$LABEL))-ulabelmax/2+1,nchar(as.character(dtemp$LABEL))))
  dtemp$ULABELtemp=as.character(paste(dtemp$ULABELtemp1,"...",dtemp$ULABELtemp2,sep=""))
  dtemp$ULABEL=as.character(dtemp$Function)
  dtemp[nchar(as.character(dtemp$LABEL))>ulabelmax,"ULABEL"]=as.character(dtemp[nchar(as.character(dtemp$LABEL))>ulabelmax, "ULABELtemp"])
  dtemp$LABEL=dtemp$ULABEL
  dtemp$VSLABEL=as.character(dtemp$Function)
  dtemp$VSLABEL=as.character(substr(dtemp$VSLABEL,1,4))
  #manage the size of the legend
  police_size=10
  if (length(func)<15){
    police_size=9
  }else if (length(func)<20){
    police_size=8
  }else if (length(func)<25){
    police_size=7
  }else if (length(func)<30){
    police_size=6
  }else{
    police_size=5
  }
  names(func)=func
  vlabels<-vector(, length(func))
  names(vlabels)=func
  for (n in func){
    labeltemps=as.vector(dtemp$LABEL[dtemp$Function %in% n])
    vlabels[n]=as.character(labeltemps[1])
  }
  dtemp$SLABEL=as.character("")
  #decide if we print the routine label entirely or not
  for (n in func){
    for (c in unique(dtemp[(dtemp$Function %in% n),"Callstack"])){
      indices=(dtemp$Function %in% n)&(dtemp$Ratio>0.2)&(dtemp$DURATION>0.12)&(dtemp$Callstack %in% c)
      i=which.max(dtemp[indices,"DURATION"])
      dtemp[indices,][i, "SLABEL"]= dtemp[indices,][i, "TLABEL"]
      if (length(i)==0){
        indices2=(dtemp$Function %in% n)&(dtemp$Ratio>0.2)&(dtemp$DURATION>0.01)&(dtemp$Callstack %in% c)
        i=which.max(dtemp[indices2,"DURATION"])
        dtemp[indices2,][i, "SLABEL"]= dtemp[indices2,][i, "VSLABEL"]
      }
    }
  }
  #filling the plot
  #manage the jesus case: we do not print space between the rectangles
  if (jesus){
    plot<-plot+geom_rect(data=dtemp, mapping=aes(xmin=START, xmax=END, ymin=OFFSET, ymax=OFFSET+Ratio, fill=Function, colour=Function))
    #show selected routine
    if (showSelected){
      plot<-plot+geom_rect(data=dtemp2, mapping=aes(xmin=START, xmax=END, ymin=OFFSET, ymax=OFFSET+Ratio, fill=NA), color="black", size=dsize)
    }
    plot<-plot+scale_colour_manual(values = vcolors)
  }
  #we print space
  else{
    plot<-plot+geom_rect(data=dtemp, mapping=aes(xmin=START, xmax=END, ymin=OFFSET, ymax=OFFSET+Ratio, fill=Function), color="white", size=dsize)
    #show selected routine
    if (showSelected){
      plot<-plot+geom_rect(data=dtemp2, mapping=aes(xmin=START, xmax=END, ymin=OFFSET, ymax=OFFSET+Ratio, fill=NA), color="black", size=dsize/3)
    }
  }
  #printing the label
  plot<-plot+geom_text(data=dtemp, aes(x=START+DURATION/2, y=OFFSET+(Ratio/2), label=SLABEL), color="white",size = 3)
  #managing the legends, labels, title, theme, etc.
  plot<-plot+scale_fill_manual(values = vcolors, breaks = sort(func), labels = vlabels)
  plot<-plot + theme_bw()
  plot<-plot + guides(color=FALSE)
  plot<-plot + theme(legend.text = element_text(size = police_size))
  plot<-plot + theme(legend.position="bottom")
  ylabel<-"Callstack level"
  title<-("Callstack vs Time")
  plot<-plot+ggtitle(title)
  plot<-plot+labs(y=ylabel)
  plot
}

#print the timeline + codelines
print_parts_codelines <- function(parts_data, codelines_data, p){
  dtemp<-parts_data[(parts_data$P %in% p),]
  dtemp<-dtemp[!(dtemp$Function %in% "void"),]
  codelines_temp<-codelines_data[(codelines_data$P %in% p),]
  xlabel<-paste("Time (relative), p=", p, sep="")
  ylabel<-"Codeline"
  title<-("Relevant Routines")
  plot<-ggplot()
  plot<-plot+scale_x_continuous(name=xlabel, limits =c(0,1))
  plot<-plot+scale_y_reverse(name=ylabel)
  plot<-plot+ggtitle(title)
  plot<-plot+geom_rect(data=dtemp, mapping=aes(xmin=START, xmax=END, fill=Function), color="white", ymin=-Inf, ymax=Inf)
  plot<-plot+geom_point(data=codelines_temp, aes(x=TS, y=Codeline), color="black", size=0.2)
  func<-unique(dtemp[["Function"]])
  vcolors=color_generator(func)
  dtemp$LABEL=as.character(dtemp$Function)
  dtemp$TLABELtemp=as.character(substr(dtemp$LABEL,1,labelmax))
  dtemp$TLABELtemp=as.character(paste(dtemp$TLABELtemp,"...",sep=""))
  dtemp$TLABEL=as.character(dtemp$Function)
  dtemp[nchar(as.character(dtemp$LABEL))>labelmax,"TLABEL"]=as.character(dtemp[nchar(as.character(dtemp$LABEL))>labelmax, "TLABELtemp"])
  dtemp$ULABELtemp1=as.character(substr(dtemp$LABEL,1,ulabelmax/2-2))
  dtemp$ULABELtemp2=as.character(substr(dtemp$LABEL,nchar(as.character(dtemp$LABEL))-ulabelmax/2+1,nchar(as.character(dtemp$LABEL))))
  dtemp$ULABELtemp=as.character(paste(dtemp$ULABELtemp1,"...",dtemp$ULABELtemp2,sep=""))
  dtemp$ULABEL=as.character(dtemp$Function)
  dtemp[nchar(as.character(dtemp$LABEL))>ulabelmax,"ULABEL"]=as.character(dtemp[nchar(as.character(dtemp$LABEL))>ulabelmax, "ULABELtemp"])
  dtemp$LABEL=dtemp$ULABEL
  dtemp$VSLABEL=as.character(dtemp$Function)
  dtemp$VSLABEL=as.character(substr(dtemp$VSLABEL,1,4))
  police_size=10
  if (length(func)<15){
    police_size=9
  }else if (length(func)<20){
    police_size=8
  }else if (length(func)<25){
    police_size=7
  }else if (length(func)<30){
    police_size=6
  }else{
    police_size=5
  }
  names(func)=func
  vlabels<-vector(, length(func))
  names(vlabels)=func
  for (n in func){
    labeltemps=as.vector(dtemp$LABEL[dtemp$Function %in% n])
    vlabels[n]=as.character(labeltemps[1])
  }
  plot<-plot+scale_fill_manual(values = vcolors, breaks = sort(func), labels = vlabels)
  plot<-plot + theme_bw()
  plot<-plot+ theme(legend.position="bottom")
  plot<-plot + guides(color=FALSE)
  plot<-plot + theme(legend.text = element_text(size = police_size))
  plot
}

#build the perf counter slope (most useful)
print_perf_counter_slope <- function(slope, counter){
  #Stats
  slope_max<-slope[which.max(slope[,"VALUE"]),"VALUE"]
  slope_mean<-mean(slope[["VALUE"]])
  #Printing
  xlabel<-"Time (relative)"
  ylabel<-"Amplitude"
  title<-paste(counter,"/s vs Time", "- Max =", ceiling(slope_max), "- Mean =", ceiling(slope_mean))
  plot<-ggplot(slope, aes(x=TS,y=VALUE))
  plot<-plot+geom_line(data=slope, size=1.2, color="blue")
  plot<-plot+scale_y_continuous(name=ylabel, expand =c(0,0))
  plot<-plot+scale_x_continuous(name=xlabel, limits =c(0,1))
  plot<-plot+ggtitle(title)
  plot<-plot+theme_bw()
  plot
}

#build the perf counter curve
print_perf_counter <- function(dump, interpolate, counter){
  #Dump
  dump$SAMPLES<-1
  excluded<-dump[(dump$TYPE %in% "e"),]
  unused<-dump[(dump$TYPE %in% "un"),]
  used<-dump[(dump$TYPE %in% "u"),]
  #Interpolate
  interpolate$TYPE<-"i"
  interpolate$SAMPLES<-0
  #Merging
  total<-rbind(rbind(rbind(excluded,unused),used),interpolate)
  #Printing
  xlabel<-"Time (relative)"
  ylabel<-"Amplitude (normalized)"
  title<-paste(counter,"vs Time")
  plot<-ggplot(total, aes(x=TS,y=VALUE,colour=TYPE))
  plot<-plot+geom_point(data=total[total$SAMPLES %in% 1,])
  plot<-plot+geom_line(data=total[total$SAMPLES %in% 0,], size=1.2)
  plot<-plot+scale_y_continuous(name=ylabel, expand =c(0,0))
  plot<-plot+scale_x_continuous(name=xlabel, limits =c(0,1))
  plot<-plot+ggtitle(title)
  plot<-plot + scale_colour_manual(name="",breaks = c("i", "u", "un", "e"), labels = c("e"="Excluded samples ", "i"="Interpolation ", "u"="Used samples ", "un"="Unused samples "), values = c("i"="green", "u"="red", "un"="yellow", "e"="grey"))
  plot<-plot+theme_bw()
  plot<-plot+theme(legend.position="bottom")
  plot
}


#MAIN

args <- commandArgs(trailingOnly = TRUE)
arg_perf_directory=args[1]
arg_instance_directory=args[2]
arg_instance_name=args[3]
arg_output_directory=args[4]
w=as.integer(args[5])
h=as.integer(args[6])
d=as.integer(args[7])
#filter routines below a certain percentage in callstack representation
filter=10
#managing the file names
dump_input=list.files(arg_perf_directory, pattern="\\.dump\\.csv$")
interpolate_input=list.files(arg_perf_directory, pattern="\\.interpolate\\.csv$")
slope_input=list.files(arg_perf_directory, pattern="\\.slope\\.csv$")
dump_input <- paste(arg_perf_directory,'/',dump_input[1], sep="")
interpolate_input <- paste(arg_perf_directory,'/',interpolate_input[1], sep="")
slope_input <- paste(arg_perf_directory,'/',slope_input[1], sep="")
#get the data from folding csv files: performance counter curve data
dump_data <-read(dump_input, cheader_dump, ';')
interpolate_data <-read(interpolate_input, cheader_interpolate, ';')
slope_data <-read(slope_input, cheader_slope, ';')
#get the data from rri csv files
qualities_input <- paste(arg_instance_directory,'/',qualities_input_file, sep="")
qualities_data <-read(qualities_input, cheader_qualities)
qualities_output <- paste(arg_output_directory,'/',qualities_output_file, sep="")
#generating pdf for qualities
ggsave(qualities_output, plot = print_qualities(qualities_data), width = w, height = w, dpi=d)
qualities2_output <- paste(arg_output_directory,'/',qualities2_output_file, sep="")
ggsave(qualities2_output, plot = print_qualities2(qualities_data), width = w, height = w, dpi=d)
info_input <- paste(arg_instance_directory,'/',info_input_file, sep="")
info_data <-read(info_input, cheader_info)
parts_input <- paste(arg_instance_directory,'/',parts_input_file, sep="")
details_input <- paste(arg_instance_directory,'/',details_input_file, sep="")
codelines_input <- paste(arg_instance_directory,'/',codelines_input_file, sep="")
parts_data <-read(parts_input, cheader_parts)
details_data <-read(details_input, cheader_details)
codelines_data <-read(codelines_input, cheader_codelines)
#plist<-make_plist(parts_data)
#for (p in plist){
#  parts_output <- paste(arg_output_directory,'/.',parts_output_basename, "_" , p, ".pdf", sep="")
#  ggsave(parts_output, plot=print_parts_codelines(parts_data, codelines_data, p), width = w, height = h, dpi=d)
#}
#p<-inflex_p(qualities_data)
#parts_output <- paste(arg_output_directory,'/',parts_output_basename, "_main_inflex", ".pdf", sep="")
#ggsave(parts_output, print_parts_codelines(parts_data, codelines_data, p), width = w, height = h, dpi=d)
#p<-inflex2_p(qualities_data)
#parts_output <- paste(arg_output_directory,'/',parts_output_basename, "_local_inflex", ".pdf", sep="")

#selecting the best partition
p<-info_data[1, "BEST"]
#generate several pdf filesi
#timeline
parts_output <- paste(arg_output_directory,'/',parts_output_basename, "_best", ".pdf", sep="")
ggsave(parts_output, print_parts_codelines(parts_data, codelines_data, p), width = w, height = h, dpi=d)
#different callstacks
parts_output <- paste(arg_output_directory,'/',parts_output_basename, "_callstack", ".pdf", sep="")
ggsave(parts_output, plot = print_details_aggreg(details_data, p, FALSE, TRUE, 0, TRUE), width = w*2, height = h*2, dpi=d)
parts_output <- paste(arg_output_directory,'/',parts_output_basename, "_callstack_jesus", ".pdf", sep="")
ggsave(parts_output, plot = print_details_aggreg(details_data, p, TRUE, TRUE, 0, TRUE), width = w*2, height = h*2, dpi=d)
plot1=print_parts_codelines(parts_data, codelines_data, p)
plot2=print_details_aggreg(details_data, p, TRUE, TRUE, filter, FALSE)
parts_output <- paste(arg_output_directory,'/',parts_output_basename, "_callstack_filter", ".pdf", sep="")
ggsave(parts_output, plot = plot2, width = w, height = h*2, dpi=d)
instance=arg_instance_name
#filter folding files to take into account only the current cluster/instance
interpolate_data<-interpolate_data[(interpolate_data$INSTANCE %in% instance),]
slope_data<-slope_data[(slope_data$INSTANCE %in% instance),]
dump_data<-dump_data[(dump_data$INSTANCE %in% instance),]
#print("Discarded counters:")
test_data=interpolate_data
discarded_counter=unique(test_data[!(is.finite(test_data$VALUE)),"COUNTER"])
#print(discarded_counter)
if (length(discarded_counter)!=0){
  test_data<-test_data[(is.finite(test_data$VALUE)),]
}
counterlist<-make_counterlist(test_data)
#iterating over all the available counters
for (counter in counterlist){
 # print(counter)
  #print juste the performance counter curves
  dump_temp<-dump_data[(dump_data$COUNTER %in% counter),]
  slope_temp<-slope_data[(slope_data$COUNTER %in% counter),]
  interpolate_temp<-interpolate_data[(interpolate_data$COUNTER %in% counter),]
  if (nrow(dump_temp)==0 | nrow(slope_temp)==0 | nrow(interpolate_temp)==0){
  #  print("Invalid data, passing")
  }
  else{
  #print timelines/callstack + performance counter curves
    plot3=print_perf_counter_slope(slope_temp, counter)
    counters_output <- paste(arg_output_directory,"/.",counter, "_slope.pdf", sep="")
    ggsave(counters_output, plot = plot3, width = w, height = h, dpi=d)
    plot4=print_perf_counter(dump_temp, interpolate_temp, counter)
    counters_output <- paste(arg_output_directory,"/.",counter, ".pdf", sep="")
    ggsave(counters_output, plot = plot4, width = w, height = h, dpi=d)
    g <- arrangeGrob(plot1, plot3, nrow=2, heights=c(1/2,1/2)) #generates g
    parts_output <- paste(arg_output_directory,'/',parts_output_basename,"_",counter,".pdf", sep="")
    ggsave(parts_output, g, width = w, height = h*2, dpi=d)
    g <- arrangeGrob(plot2, plot3, nrow=2, heights=c(2/3,1/3)) #generates g
    parts_output <- paste(arg_output_directory,'/',parts_output_basename,"_",counter,"_callstack.pdf", sep="")
    ggsave(parts_output, g, width = w, height = h*2, dpi=d)
  }
}
#warnings()

