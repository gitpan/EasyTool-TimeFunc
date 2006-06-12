require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
        'NAME' => 'EasyTool-TimeFunc',
        'VERSION'       =>      '1.0.0',
        dist            =>      { COMPRESS => 'gzip -9f', SUFFIX => 'gz'}
);