#include "precompiled.h"

#include "ThreadUtils.h"
#include "AppLogFetcher.h"
#include "CommonConstants.h"
#include "Logger.h"
#include "JlCompress.h"
#include "Report.h"

#define BACKUP_ZIP_PASSWORD "N9*09m5*1hZz7_*"

namespace safebrowse {

using namespace canadainc;

void ThreadUtils::compressFiles(Report& r, QString const& zipPath, const char* password)
{
    if (r.type == ReportType::BugReportAuto || r.type == ReportType::BugReportManual) {
        r.attachments << DATABASE_PATH;
    }

    JlCompress::compressFiles(zipPath, r.attachments, password);
}


BackupStruct ThreadUtils::compressDatabase(BackupStruct bs)
{
    bool result = JlCompress::compressFile(bs.destination, DATABASE_PATH, BACKUP_ZIP_PASSWORD);
    QFileInfo f(bs.destination);

    if ( !result || f.size() == 0 ) {
        bs.destination = "";
    } else {
        bs.destination = f.fileName();
    }

    return bs;
}

BackupStruct ThreadUtils::performRestore(BackupStruct bs)
{
    LOGGER("*** SDLKLJ" << bs.destination);
    QStringList files = JlCompress::extractDir( bs.destination, QDir::homePath(), BACKUP_ZIP_PASSWORD );

    if ( files.isEmpty() ) {
        bs.destination = "";
    }

    return bs;
}


} /* namespace autoblock */
