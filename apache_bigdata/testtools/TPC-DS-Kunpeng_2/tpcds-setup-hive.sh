#!/bin/bash
# Copyright (c) 2023. Huawei Technologies Co.,Ltd.ALL rights reserved.
# This program is licensed under Mulan PSL v2.
# You can use it according to the terms and conditions of the Mulan PSL v2.
#          http://license.coscl.org.cn/MulanPSL2
# THIS PROGRAM IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.

# #############################################
# @Author    :   hekeming
# @Contact   :   hk16897@126.com
# @Date      :   2023/07/03
# @License   :   Mulan PSL v2
# @Desc      :   Test SSH link
# ############################################

function usage {
	echo "Usage: tpcds-setup.sh scale_factor [text/orc]"
        echo "Example: sh tpcds-setup.sh 100 orc "
	exit 1
}

if [ ! -f tpcds-gen/target/tpcds-gen-1.0-SNAPSHOT.jar ]; then
	echo "Please build the data generator with ./tpcds-build.sh first"
	exit 1
fi
if [ $? -ne 0 ]; then
	echo "Script must be run where Hive is installed"
	exit 1
fi
function runcommand_text {
	if [ "X$DEBUG_SCRIPT" != "X" ]; then
		$1 >>"${TEXT_1_LOG}"
	else
		$1 >>"${TEXT_1_LOG}" 2>>"${TEXT_2_LOG}"
	fi
}

function runcommand {
        if [ "X$DEBUG_SCRIPT" != "X" ]; then
                $1 >>"${SQL_1_LOG}"
        else
                $1 >>"${SQL_1_LOG}" 2>>"${SQL_2_LOG}"
        fi
}

# Tables in the TPC-DS schema.
DIMS="date_dim time_dim item customer customer_demographics household_demographics customer_address store promotion warehouse ship_mode reason income_band call_center web_page catalog_page web_site"
FACTS="store_sales store_returns web_sales web_returns catalog_sales catalog_returns inventory"

# Get the parameters.
SCALE=$1
DIR=$4

BUCKETS=13
DATABASE="tpcds_text_hive_${SCALE}"
DATABASE_TEXT="tpcds_text_hive_${SCALE}"

# Sanity checking.
if [ X"$SCALE" = "X" ]; then
	usage
fi
if [ X"$DIR" = "X" ]; then
	DIR=/tmp/tpcds-generate
fi
if [ $SCALE -eq 1 ]; then
	echo "Scale factor must be greater than 1"
	exit 1
fi

# Generate command_prefix according to the deploy_type
deploy_mode=$3

hive_home=$(command -v hive)
beeline_cmd=$(echo ${hive_home%/*}/beeline)
echo "[INFO] beeline path: ${beeline_cmd}"

case ${deploy_mode} in
    tar)
	beeline_command_prefix="${beeline_cmd} -n root -u jdbc:hive2://localhost:10000"
        ;;
    ambari)
	beeline_command_prefix="${beeline_cmd} -n hdfs -p admin"
        ;;
    *)
        echo "[ERROR] unknown deploy mode!"
        exit 1
esac


# Do the actual data load.
hdfs dfs -mkdir -p ${DIR}
hdfs dfs -ls ${DIR}/${SCALE} > /dev/null
if [ $? -ne 0 ]; then
	echo "Generating data at scale factor $SCALE."
	(cd tpcds-gen; hadoop jar target/*.jar -d ${DIR}/${SCALE}/ -s ${SCALE})
fi
hdfs dfs -ls ${DIR}/${SCALE} > /dev/null
if [ $? -ne 0 ]; then
	echo "Data generation failed, exiting."
	exit 1
fi
echo "TPC-DS text data generation complete."

# Create the text/flat tables as external tables. These will be later be converted to ORCFile.
echo "Loading text data into external tables."
rm -rf example/${DATABASE}
mkdir -p example/${DATABASE}/log
cp  ddl-tpcds/text/alltables.sql  example/${DATABASE}/
sed -i "s/\${DB}/${DATABASE}/g" example/${DATABASE}/alltables.sql
sed -i "s:\${LOCATION}:${DIR}\/${SCALE}:" example/${DATABASE}/alltables.sql

TEXT_1_LOG="example/${DATABASE}/log/alltables_1.log"
TEXT_2_LOG="example/${DATABASE}/log/alltables_2.log"

runcommand_text  "${beeline_command_prefix} -i settings/load-flat.sql -f example/${DATABASE}/alltables.sql"

if [ $? -eq 0 ]; then
       echo "Data loaded into database ${DATABASE}."
fi


if [ $2 = "text"  ]; then
       exit 0
elif [ $2 = "orc" ] ;then
     DATABASE="tpcds_orc_hive_${SCALE}"
fi
i=1
total=24
rm -rf example/${DATABASE}
mkdir -p example/${DATABASE}/log
mkdir -p example/${DATABASE}/bin_partitioned

for t in ${FACTS}
do
	SQL_1_LOG="example/${DATABASE}/log/${t}_1.log"
	SQL_2_LOG="example/${DATABASE}/log/${t}_2.log"
	echo "Optimizing table $t ($i/$total)."
        cp   ddl-tpcds/bin_partitioned/${t}.sql example/${DATABASE}/bin_partitioned/${t}.sql
	sed -i "s/\${DB}/${DATABASE}/g"  example/${DATABASE}/bin_partitioned/${t}.sql
        sed -i "s/\${SOURCE}/${DATABASE_TEXT}/g"  example/${DATABASE}/bin_partitioned/${t}.sql
        sed -i "s/\${BUCKETS}/${BUCKETS}/g"  example/${DATABASE}/bin_partitioned/${t}.sql
        sed -i "s/\${FILE}/orc/g"  example/${DATABASE}/bin_partitioned/${t}.sql
	
        COMMAND="${beeline_command_prefix} -i settings/load-partitioned.sql -f example/${DATABASE}/bin_partitioned/${t}.sql"
	echo "the cmd:"$COMMAND
	runcommand "$COMMAND"
	if [ $? -ne 0 ]; then
		echo "Command failed, try 'export DEBUG_SCRIPT=ON' and re-running"
		exit 1
	fi
	i=`expr $i + 1`
done

# Populate the smaller tables.
for t in ${DIMS}
do
        SQL_1_LOG="example/${DATABASE}/log/${t}_1.log"
	SQL_2_LOG="example/${DATABASE}/log/${t}_2.log"
	echo "Optimizing table $t ($i/$total)."
        cp   ddl-tpcds/bin_partitioned/${t}.sql example/${DATABASE}/bin_partitioned/${t}.sql
	sed -i "s/\${DB}/${DATABASE}/g"  example/${DATABASE}/bin_partitioned/${t}.sql
        sed -i "s/\${SOURCE}/${DATABASE_TEXT}/g"  example/${DATABASE}/bin_partitioned/${t}.sql
        sed -i "s/\${FILE}/orc/g"  example/${DATABASE}/bin_partitioned/${t}.sql
	COMMAND="${beeline_command_prefix} -i settings/load-partitioned.sql -f example/${DATABASE}/bin_partitioned/${t}.sql"
	echo "the cmd:"$COMMAND
	runcommand "$COMMAND"
	if [ $? -ne 0 ]; then
		echo "Command failed, try 'export DEBUG_SCRIPT=ON' and re-running"
		exit 1
	fi
	i=`expr $i + 1`
done

echo "Data loaded into database ${DATABASE}."
