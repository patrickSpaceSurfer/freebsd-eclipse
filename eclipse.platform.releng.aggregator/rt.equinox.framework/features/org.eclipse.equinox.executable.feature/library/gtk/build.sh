#!/bin/sh
#*******************************************************************************
# Copyright (c) 2000, 2018 IBM Corporation and others.
#
# This program and the accompanying materials
# are made available under the terms of the Eclipse Public License 2.0
# which accompanies this distribution, and is available at 
# https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#     Kevin Cornell (Rational Software Corporation)
# Martin Oberhuber (Wind River) - [176805] Support building with gcc and debug
# Martin Oberhuber (Wind River) - [517013] Avoid memcpy@GLIBC_2.14 dependency
#*******************************************************************************
#
# Usage: sh build.sh [<optional switches>] [clean]
#
#   where the optional switches are:
#       -output <PROGRAM_OUTPUT>  - executable filename ("eclipse")
#       -os     <DEFAULT_OS>      - default Eclipse "-os" value
#       -arch   <DEFAULT_OS_ARCH> - default Eclipse "-arch" value
#       -ws     <DEFAULT_WS>      - default Eclipse "-ws" value
#       -java <JAVA_HOME>  - java install for jni headers
#
#   All other arguments are directly passed to the "make" program.
#   This script can also be invoked with the "clean" argument.
#
#   Examples:
#   sh build.sh clean
#   sh build.sh -java /usr/j2se OPTFLAG=-g PICFLAG=-fpic

cd `dirname $0`

# Define default values for environment variables used in the makefiles.
programOutput="eclipse"
defaultOS=""
defaultOSArch=""
defaultWS="gtk"
EXEC_DIR=../../../../../rt.equinox.binaries/org.eclipse.equinox.executable
defaultJava=DEFAULT_JAVA_JNI
defaultJavaHome=""
javaHome=""
makefile=""
if [ "${CC}" = "" ]; then
	CC=cc
	export CC
fi

# Parse the command line arguments and override the default values.
extraArgs=""
while [ "$1" != "" ]; do
    if [ "$1" = "-os" ] && [ "$2" != "" ]; then
        defaultOS="$2"
        shift
    elif [ "$1" = "-arch" ] && [ "$2" != "" ]; then
        defaultOSArch="$2"
        shift
    elif [ "$1" = "-ws" ] && [ "$2" != "" ]; then
        defaultWS="$2"
        shift
    elif [ "$1" = "-output" ] && [ "$2" != "" ]; then
        programOutput="$2"
        shift
    elif [ "$1" = "-java" ] && [ "$2" != "" ]; then
        javaHome="$2"
        shift
    else
        extraArgs="$extraArgs $1"
    fi
    shift
done
if [ "$defaultOS" = "" ];  then
    defaultOS=`uname -s`
fi
if [ "$defaultOSArch" = "" ];  then
	defaultOSArch=`uname -m`
fi


case $defaultOS in
	"Linux" | "linux")
		makefile="make_linux.mak"
		defaultOS="linux"
		case $defaultOSArch in
			"x86_64")
				defaultOSArch="x86_64"
				defaultJava=DEFAULT_JAVA_EXEC
				[ -d /bluebird/teamswt/swt-builddir/JDKs/x86_64/jdk1.5.0 ] && defaultJavaHome="/bluebird/teamswt/swt-builddir/JDKs/x86_64/jdk1.5.0"
				;;
			"ppc64le")
				defaultOSArch="ppc64le"
				defaultJava=DEFAULT_JAVA_EXEC
				#[ -d /bluebird/teamswt/swt-builddir/JDKs/PPC64LE/ibm-java2-ppc64le-50 ] && defaultJavaHome="/bluebird/teamswt/swt-builddir/JDKs/PPC64LE/ibm-java2-ppc64le-50"
				defaultJavaHome=`readlink -f /usr/bin/java | sed "s:jre/bin/java::"`
				OUTPUT_DIR="$EXEC_DIR/bin/$defaultWS/$defaultOS/$defaultOSArch"
				;;
			"s390x")
				defaultOSArch="s390x"
				defaultJava=DEFAULT_JAVA_EXEC
				OUTPUT_DIR="$EXEC_DIR/contributed/$defaultWS/$defaultOS/$defaultOSArch"
				;;
            "aarch64")
				defaultOSArch="aarch64"
				defaultJava=DEFAULT_JAVA_EXEC
				OUTPUT_DIR="$EXEC_DIR/bin/$defaultWS/$defaultOS/$defaultOSArch"
				;;
			*)
				echo "*** Unknown MODEL <${MODEL}>"
				;;
		esac
		;;
	FreeBSD|freebsd)
		defaultOS="freebsd"
		defaultJava=DEFAULT_JAVA_EXEC
		makefile="make_linux.mak"
		;;
	*)
	echo "Unknown OS $defaultOS -- build aborted"
	;;
esac
export CC


# Set up environment variables needed by the makefiles.
PROGRAM_OUTPUT="$programOutput"
DEFAULT_OS="$defaultOS"
DEFAULT_OS_ARCH="$defaultOSArch"
DEFAULT_WS="$defaultWS"
DEFAULT_JAVA=$defaultJava

origJavaHome=$JAVA_HOME
if [ -n  "$javaHome" ]; then
	JAVA_HOME=$javaHome
	export JAVA_HOME
elif [ -z "$JAVA_HOME" -a -n  "$defaultJavaHome" ]; then
	JAVA_HOME="$defaultJavaHome"
	export JAVA_HOME
fi

if [ $defaultOSArch = "ppc64le" ];  then
	M_ARCH=-m64
	export M_ARCH
elif [ "$defaultOSArch" = "s390x" ];  then
	if [ "${JAVA_HOME}" = "" ]; then
		export JAVA_HOME="/home/swtbuild/java5/s390x/ibm-java2-s390x-50"
	fi
fi

LIBRARY_DIR="$EXEC_DIR/../org.eclipse.equinox.launcher.$defaultWS.$defaultOS.$defaultOSArch"
OUTPUT_DIR="$EXEC_DIR/bin/$defaultWS/$defaultOS/$defaultOSArch"
mkdir -p ${OUTPUT_DIR}

export OUTPUT_DIR PROGRAM_OUTPUT DEFAULT_OS DEFAULT_OS_ARCH DEFAULT_WS DEFAULT_JAVA LIBRARY_DIR

# If the OS is supported (a makefile exists)
if [ "$makefile" != "" ]; then
	if [ "$extraArgs" != "" ]; then
		gmake -f $makefile $extraArgs
	else
		echo "Building $OS launcher. Defaults: -os $DEFAULT_OS -arch $DEFAULT_OS_ARCH -ws $DEFAULT_WS"
		gmake -f $makefile clean
		case x$CC in
		  x*gcc*) gmake -f $makefile all PICFLAG=-fpic ;;
		  *)      gmake -f $makefile all ;;
		esac
	fi
else
	echo "Unknown OS $OS -- build aborted"
fi

#restore original JAVA_HOME
JAVA_HOME="$origJavaHome"
export JAVA_HOME
