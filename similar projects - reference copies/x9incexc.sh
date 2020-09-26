#!/bin/bash
# shellcheck disable=2004  ## Inappropriate complaining of "$/${} is unnecessary on arithmetic variables."
# shellcheck disable=2034  ## Unused variables.
# shellcheck disable=2119  ## Disable confusing and inapplicable warning about function's $1 meaning script's $1.
# shellcheck disable=2155  ## Disable check to 'Declare and assign separately to avoid masking return values'.
# shellcheck disable=2120  ## OK with declaring variables that accept arguments, without calling with arguments (this is 'overloading').
# shellcheck disable=2001  ## Complaining about use of sed istead of bash search & replace.

##	Purpose: See fPrint_About() below.
##	History:
##		- 20200827 JC: Created from TEMPLATE_single-file_20200827.
##		- 20200828 JC:
##			- Fleshed out options.
##			- Added packed args.

set -e; set -E


## Template constants
declare -i    doDebug=0
declare -i    runAsSudo=1
declare -i    doQuietly=0; if [[ ${GENERATEFILELIST_QUIET} -eq 1 ]]; then doQuietly=1; fi


function fPrint_About(){ _fdbgEnter "${FUNCNAME[0]}";
	##	Purpose:
	##		- Prints to stdout, general high-level description.
	##		- Listed first in script only for easy of maintainability.
	##	History:
	##		- 20190911 JC: Created template.
	#            X"                                                                               "X
	if [[ ${doQuietly} -eq 0 ]]; then
		_fEcho_Clean ""
		_fEcho_Clean "Generates a list of files filtered by regex, date, and/or size. The output can"
		_fEcho_Clean "be fed into other programs (e.g. rsync), usually via '--files-from' type flag."
		_fEcho_Clean ""
	fi
_fdbgEgress "${FUNCNAME[0]}"; }


function fPrint_Syntax(){ _fdbgEnter "${FUNCNAME[0]}";
	##	Purpose:
	##		- Prints to stdout, the syntax.
	##		- Listed second in script only for easy of maintainability (fMain() is actually
	##	History:
	##		- 20190911 JC: Created template.
	if [[ ${doQuietly} -eq 0 ]]; then
		#           X"                                                                               "X
		_fEcho_Clean ""
		_fEcho_Clean "Arguments; all optional; nothing is case-sensitive except file|folder names:"
		_fEcho_Clean "    --oldest <x> <unitsX>, --newest <y> <unitsY>"
		_fEcho_Clean "        Only include files between x <unitsX> and y <unitsY> old."
		_fEcho_Clean "        Units: minutes|hours|days|weeks|months|years."
		_fEcho_Clean "        Aliases: anything starting with: mi, h, d, w, mo, y."
		_fEcho_Clean "        Either or both can be left out to all older or newer."
		_fEcho_Clean "    --after <date/time1>, --before <date/time2>"
		_fEcho_Clean "        Only include files between <date/time1> and <date/time2>."
		_fEcho_Clean "        Format: Anything that 'find' will accept, e.g. 'YYYY-MM-DD HH:MM:SS'."
		_fEcho_Clean "        Either or both can be left out to all older or newer."
		_fEcho_Clean "    --smallest <x> <unitsX>, --biggest <y> <unitsY>"
		_fEcho_Clean "        Only include files between x <unitsX> and y <unitsY> in size."
		_fEcho_Clean "        Units: B|KB|MB|GB|TB; all base 2."
		_fEcho_Clean "        Aliases: anything starting with: b, k, m, g, t."
		_fEcho_Clean "        Either or both can be left out to all smaller or bigger."
		_fEcho_Clean "    --patterns-from <filespec>"
		_fEcho_Clean "        A text file with a list of include and exclude patterns."
		_fEcho_Clean "        Unlike the bass-ackward rsync-style order of processing, these are"
		_fEcho_Clean "            processed in a logical order, as a human reads from top to bottom."
		_fEcho_Clean "            For example, if a folder is excluded, a more deeply nested pattern"
		_fEcho_Clean "            might be added back in, then an even deeper pattern re-removed"
		_fEcho_Clean "            later, and so on."
		_fEcho_Clean "        This is done very simply, in a way that makes much more sense than the"
		_fEcho_Clean "            confusing rsync-style include/exclude logic: 1) Include matches are"
		_fEcho_Clean "            always (and only) copied from an original immutable list, and"
		_fEcho_Clean "            appended to a 'working set' that starts blank. 2) Exclude matches"
		_fEcho_Clean "            are always (and only) removedfrom the 'working set'. Thus, any"
		_fEcho_Clean "            complexity can be acheived (including re-adding and re-removing the"
		_fEcho_Clean "            same lines repeatedly, if so desired for some reason)."
		_fEcho_Clean "        Blanks, comment lines (#), and leading/trailing whitespace are ignored."
		_fEcho_Clean "        Format: <+|-><cs|ci>:<type>:<expression>"
		_fEcho_Clean "            <+|->"
		_fEcho_Clean "                + Append matches from orig immutible list, to working set."
		_fEcho_Clean "                - Remove matches from working set."
		_fEcho_Clean "            <cs|ci>: Case-sensitivity:"
		_fEcho_Clean "                ci: Case-sensitive"
		_fEcho_Clean "                ci: Case-INsensitive"
		_fEcho_Clean "            <type>"
		_fEcho_Clean "                re: Perl-compatible regular expression."
		_fEcho_Clean "                sh: Shell-style expressions. These are converted into regex:"
		_fEcho_Clean "                    '?'   -> '?'; One of anything except path separator."
		_fEcho_Clean "                    '*'   -> '([^\/]+)'; One file or folder of any name."
		_fEcho_Clean "                    '**'  -> '(.*)'; Anything, including path separator."
		_fEcho_Clean "                    'xyz' -> '(^|.*\/)xyz(\/.*|$)'; +ancestors and descendants."
		_fEcho_Clean "                x9: Purpose-focused expressions, converted into regex (most"
		_fEcho_Clean "                    symbols here are unicode, not on keyboard). Standard regex"
		_fEcho_Clean "                    is also valid.:"
		_fEcho_Clean "                    '►'   -> '(^|.*/)'; Start of folder or file +ancestors."
		_fEcho_Clean "                    '◄'   -> '(/.*|$)'; End of file or folder +descendants."
		_fEcho_Clean "                    '✿✿'  -> '(.*)'; Anything, including path separator."
		_fEcho_Clean "                    '✿'   -> '([^/]+)'; One file or folder of any name."
		_fEcho_Clean "                    '•'   -> '\.'; period."
		_fEcho_Clean "                    '△△'  -> '([^a-zA-Z])*'; 0+ nums, delims, or path sep."
		_fEcho_Clean "                    '△'   -> '([^a-zA-Z0-9])*'; 0+ delimiters or path sep."
		_fEcho_Clean "                    '/'   -> '(\/|\\)'; Regular forward slash, to escaped *nix"
		_fEcho_Clean "                          forward slash ~or~ Windows backslash."
		_fEcho_Clean "                    '('   -> '(?:'; Except already non-matching or escaped."
		#           X"                                                                               "X
	#	_fEcho_Clean "    --OldestD <x>, --NewestD <y>"
	#	_fEcho_Clean "        Only include files between x and y days old."
	#	_fEcho_Clean "        Default: 0 = ignore."
	#	_fEcho_Clean "    --SmallestMiB <x>, --LargestMiB <y>"
	#	_fEcho_Clean "    --filter-macros_from <filespec> <macro1>[,<macro2[,...macroN]]"
	#	_fEcho_Clean "        A script that, takes one or more macros, echos a regex string."
	#	_fEcho_Clean "        Overrides --FileTypeMacro built-ins."
		_fEcho_Clean "    --filter-macros_builtin <macro1>[,<macro2[,...macroN]]"
		_fEcho_Clean "        A string matching a predefined macro, standing in for a file type regex."
		_fEcho_Clean "        Example: --FileTypeMacro \"photos-lossy\""
		_fEcho_Clean "        See below for predefined options in this script."
		_fEcho_Clean "        Use --FileTypeMacroScript <string> to override with your own."
#		_fEcho_Clean "    --final-filter \"filter string\""
#		_fEcho_Clean "        One last filter pass, using --patterns-from syntax."
		_fEcho_Clean "    --output-file <filespec>"
		_fEcho_Clean "        Filespec of output list of included files."
		_fEcho_Clean "    --output-file_excluded <filespec>"
		_fEcho_Clean "        Filespec of output list of excluded files. (Handy for troubleshooting.)"
		_fEcho_Clean "    [Folder 1 to scan] (defaults to '.')."
		_fEcho_Clean "    [Folder 2 to scan]"
		_fEcho_Clean "    ..."
		_fEcho_Clean "    [Folder N to scan]"
		_fEcho_Clean ""
		_fEcho_Clean "Built-in matches for --FilterMacro:"
		_fEcho_Clean "    photos-web ..........: .jpg, .jpeg, .gif"
		_fEcho_Clean "    photos-raw ..........: Many predefined camera raw extensions"
		_fEcho_Clean "    photos-all|images ...: Both of above, plus many more image and editor types"
		_fEcho_Clean "    documents|docs ......: Many predefined office-ish extensions"
	fi
_fdbgEgress "${FUNCNAME[0]}"; }


function fPrint_Copyright(){ _fdbgEnter "${FUNCNAME[0]}";
	##	History:
	##		- 20190911 JC: Created template.
	##	Accesses calling function variables:
	##			Read-only ....: _thisVersion
	##			Read/write ...:
	if [[ ${doQuietly} -eq 0 ]]; then
		_fEcho_Clean ""
		_fEcho_Clean "${meName} version ${_thisVersion}"
		_fEcho_Clean "Copyright (c) 2020 James Collier."
		_fEcho_Clean "License GPLv3+: GNU GPL version 3 or later, full text at:"
		_fEcho_Clean "    https://www.gnu.org/licenses/gpl-3.0.en.html"
		_fEcho_Clean "There is no warranty, to the extent permitted by law."
		_fEcho_Clean ""
	fi
_fdbgEgress "${FUNCNAME[0]}"; }


function fMain(){ _fdbgEnter "${FUNCNAME[0]}";
	##	Purpose: Main script entry point.
	##	History:
	##		- 20190911 JC: Created template.
	##		- 20200620 JC: Simplified template.

	## Pre-validation

	## Template constants (this gest run twice if $runAsSudo == 1)
	local    -r _thisVersion="0.0.1"
	local    -r _dir_BaseLogDirUnder_userHome="var/log"  ## Must not have beginning or ending slashes! (TODO: Detect and accomodate absolute path)
	local    -r doDebug="${doDebug}"  ## Make immutible for rest of script.
	local    -r meName="${meName}"    ## Make immutible for rest of script.
	local       _userName="${SUDO_USER}"; if [[ -z "${_userName}" ]]; then _userName="${USER}"; fi; local -r _userName="${_userName}"
	local    -r _userHome="${HOME}"
	local    -r _serialDT="$(date "+%Y%m%d-%H%M%S")"
	local    -r filespec_Log="${_userHome}/${_dir_BaseLogDirUnder_userHome}/${meName}/${meName}_${_serialDT}.log"

	## Parameters
	local    -r packedArgs="$1"; shift || true  ## Get packed args and shift original back to 1.
	local    -r _allArgs="$*"
	local       findOptions=""

	## Variables
	local -a foldersToScanArray=()
	local -a optionString_forFind=""

	## Initialize and validate (first arg is packed args; second is original non-packed first)
	fInit "${packedArgs}" "${_allArgs}"

	## Freeze
	local    -r findOptions="${findOptions}"

	if [[ ${doSkipIntroStuff} -eq 0 ]]; then

		if [[ ${doQuietly} -eq 0 ]]; then
			_fEcho ""
			fPrint_Copyright
			fPrint_About
		fi

		## Show sudo status
		if [[ ${runAsSudo} -eq 1 ]] && [[ "$EUID" != "0" ]]; then
			if [[ -z "$(sudo -n ls / 2>/dev/null || true)" ]]; then
				_fEcho_Clean "You will be promted for sudo permissions."
			else
				if [[ ${doQuietly} -eq 1 ]]; then
					_fThrowError "${meName}.${FUNCNAME[0]}(): Will need to prompt for password, but running in 'quiet' mode."
				else
					_fEcho_Clean "This will be run under existing sudo or root permissions."
				fi
			fi
		fi

		## Prompt to continue
		if [[ ${doQuietly} -eq 0 ]]; then
			fPromptToContinue
			_fEcho ""
		fi

		## Check if running as sudo/root; call recursively if not.
		if [[ ${runAsSudo} -eq 1 ]] && [[ "$EUID" != "0" ]]; then
			if [[ -z "$(sudo -n ls / 2>/dev/null || true)" ]]; then
				_fEcho "Verifying sudo ..."
				sudo echo "[ Sudo verified. ]"
			fi
			_fEcho "Relaunching via sudo ..."
			sudo "${0}" "reran_withsudo" "${packedArgs}" "${_allArgs}"
			exit 0
		fi
	fi

	##
	## Make it so
	##
	_fEcho
	_fEcho "Doing stuff ..."


	## Hard-coded flags
	#	-regextype posix-extended
	#	-type d,f,l

	## Useful flags which might be passed
	#	-executable
	#	-samefile
	#	-mtime n
	#	-size n[cwbkMG]
	#	-newermt 2014-08-31 ! -newermt 2014-09-30
	#	-mtime <days>


	## Finished
	_fEcho ""
	_fEcho "Done."

_fdbgEgress "${FUNCNAME[0]}"; }


function fInit(){ _fdbgEnter "${FUNCNAME[0]}";
	##	History:
	##		- 20190911 JC: Created template.
	##		- 20200620 JC: Consolidated all fInit* and fValidate* into here.

	## Constants

	## Variables
	local tmpStr=""
	local -a argsArray=()

	## Unpack args
	fUnpackArgs_ToArrayPtr "${packedArgs}" argsArray

	## Add a last element that we'll ignore, so that our loop validates last argument (a bit of a kludge)
	argsArray+=("EOF_never-match_oiuywqerjk82k3jhg87r")

	## Determine if we need to show help
	case " ${_allArgs,,} " in
		*" -h "*|*" --help "*)                 fPrint_Syntax; exit 0 ;;
		*" -v "*|*" --ver "*|*" --version "*)  fPrint_Syntax; exit 0 ;;
	esac
	if [[ -z "$(_fStrTrim_byecho "${_allArgs}")" ]]; then fPrint_Syntax; exit 1; fi

	## Validate
	_fMustBeInPath basename
	_fMustBeInPath dirname
	_fMustBeInPath bc
#	_fMustBeInPath realpath

	_fEcho "Processing input args ..."

	## Local variables to store parsed values (but not persistent beyond this scope); leave as strings, will check types later
	local opt_NewerThan_Val=""
	local opt_NewerThan_Unit=""
	local opt_Newest_Val=""
	local opt_Newest_Unit=""
	local opt_After=""
	local opt_Before=""
	local opt_Smallest_Val=""
	local opt_Smallest_Unit=""
	local opt_Biggest_Val=""
	local opt_Biggest_Unit=""
	local opt_PatternsFromFilespec=""
	local opt_FilterMacros=""
	local opt_Filespec_Output_Included=""
	local opt_Filespec_Output_Included_Excluded=""

	## Init for loop
	local currentArg=""
	local -i argCount=${#argsArray[@]}
	local -i expectingNonSwitch=0
	local -i doError_TooManySwitchParams=0
	local    lastSwitch=""
	local    tmpStr=""

	## Parse arguments
	for ((i = 0 ; i < ${argCount} ; i++)); do

		## Get next argument on the stack
		currentArg="${argsArray[$i]}"
		if [[ -n "${currentArg}" ]]; then

			### Debug
			#_fEcho "Debug: currentArg = '${currentArg}'"  ## Debug

			if [[ ${currentArg,,} =~ ^--[^\ \-]+ ]]; then :;
				## It's an option switch; see if we're expecting a positional arg instead
				if [[ ${expectingNonSwitch} -eq 1 ]]; then
					_fThrowError "${meName}.${FUNCNAME[0]}(): Expecting a non-switch argument for '${lastSwitch}', instead got '${currentArg}'."
				else :;

					## Validate switches, and act on unary switches
					tmpStr="${currentArg,,}"  ## Lower case
					tmpStr="${tmpStr:2}"      ## Strip dashes off
					lastSwitch="${tmpStr}"    ## Remember lastSwitch
					case "${tmpStr}" in
						## Unitary switches (that take no extra params
						#) : ;;
						## Everything else, expecting a non-switch for next argument
						*)	expectingNonSwitch=1 ;;
					esac

				fi
			else

				## It's not a switch
				doError_TooManySwitchParams=0
				case "${lastSwitch}" in
					"newer-than"|"oldest")
						if   [[ -z "${opt_NewerThan_Val}" ]]; then    local opt_NewerThan_Val="${currentArg}"
						elif [[ -z "${opt_NewerThan_Unit}" ]]; then   local opt_NewerThan_Unit="${currentArg}"; expectingNonSwitch=0
						else doError_TooManySwitchParams=1; fi ;;
					"newest"|"older-than")
						if   [[ -z "${opt_Newest_Val}" ]]; then    local opt_Newest_Val="${currentArg}"
						elif [[ -z "${opt_Newest_Unit}" ]]; then   local opt_Newest_Unit="${currentArg}"; expectingNonSwitch=0
						else doError_TooManySwitchParams=1; fi ;;
					"after"|"after-date")
						if   [[ -z "${opt_After}" ]]; then         local opt_After="${currentArg}"; expectingNonSwitch=0
						else doError_TooManySwitchParams=1; fi ;;
					"before"|"before-date")
						if   [[ -z "${opt_Before}" ]]; then        local opt_Before="${currentArg}"; expectingNonSwitch=0
						else doError_TooManySwitchParams=1; fi ;;
					"smallest"|"larger-than"|"bigger-than")
						if   [[ -z "${opt_Smallest_Val}" ]]; then  local opt_Smallest_Val="${currentArg}"
						elif [[ -z "${opt_Smallest_Unit}" ]]; then local opt_Smallest_Unit="${currentArg}"; expectingNonSwitch=0
						else doError_TooManySwitchParams=1; fi ;;
					"biggest"|"largest"|"smaller-than")
						if   [[ -z "${opt_Biggest_Val}" ]]; then   local opt_Biggest_Val="${currentArg}"
						elif [[ -z "${opt_Biggest_Unit}" ]]; then  local opt_Biggest_Unit="${currentArg}"; expectingNonSwitch=0
						else doError_TooManySwitchParams=1; fi ;;
					"patterns-from")
						if   [[ -z "${opt_PatternsFromFilespec}" ]]; then local opt_PatternsFromFilespec="${currentArg}"; expectingNonSwitch=0
						else doError_TooManySwitchParams=1; fi ;;
					"filter-macros_builtin")
						if   [[ -z "${opt_FilterMacros}" ]]; then  local opt_FilterMacros="${currentArg}"; expectingNonSwitch=0
						else doError_TooManySwitchParams=1; fi ;;
					"output-file")
						if   [[ -z "${opt_Filespec_Output_Included}" ]]; then local opt_Filespec_Output_Included="${currentArg}"; expectingNonSwitch=0
						else doError_TooManySwitchParams=1; fi ;;
					"output-file_excluded")
						if   [[ -z "${opt_Filespec_Output_Included_Excluded}" ]]; then local opt_Filespec_Output_Included_Excluded="${currentArg}"; expectingNonSwitch=0
						else doError_TooManySwitchParams=1; fi ;;

					## There was no switch; we're switchless for now. (Ideally, at the end of the argument string, but it will still work if not as long as switchless args are in expected order.)
					"")
						if   [[ "${currentArg}" != "EOF_never-match_oiuywqerjk82k3jhg87r" ]]; then  ## If it does match that, do nothing, loop will end
							foldersToScanArray+=("${currentArg}")
						fi
						;;

					## Unrecognized switch
					*) _fThrowError "${meName}.${FUNCNAME[0]}(): 'Unrecognized switch: '--${lastSwitch}'." ;;
				esac

				## Check if should throw an error
				if [[ ${doError_TooManySwitchParams} -eq 1 ]]; then _fThrowError "${meName}.${FUNCNAME[0]}(): 'At least one too many parameters for '${lastSwitch}': '${currentArg}'."; fi

				## If a given switch's parameters have been satisfied, clear 'lastSwitch' so that we can also accept non-switch arguments.
				if [[ ${expectingNonSwitch} -eq 0 ]]; then lastSwitch=""; fi

			fi
		fi
	done

	## Process parsed arguments
	if [[ ${#foldersToScanArray[@]} -le 0 ]]; then
		_fThrowError "${meName}.${FUNCNAME[0]}(): No scan folder[s] were specified."
	else :;

		## Intermediate variables used for building find options
		local partialOptStr_NewerThan=""

		## Temp working string for use with _fstrAppend_byglobal()
		_fstrAppend_byglobal_val=""

		if [[ -n "${opt_NewerThan_Val}" ]]; then
			tmpStr="--newer-than"  ## num unit
			if [[ $(_fIsNum_v2 "${opt_NewerThan_Val}") -eq 0 ]]; then _fThrowError "${meName}.${FUNCNAME[0]}(): Value for '${tmpStr}' isn't a number: '${opt_NewerThan_Val}'."
			elif [[ ${opt_NewerThan_Val} -lt 0 ]]; then               _fThrowError "${meName}.${FUNCNAME[0]}(): Value for '${tmpStr}' isn't >=0: '${opt_NewerThan_Val}'."
			else
				case "${opt_NewerThan_Unit,,}" in
					"mi"*) partialOptStr_NewerThan="-mmin -${opt_NewerThan_Val}"
					"h"*)  partialOptStr_NewerThan="-mmin -$(( opt_NewerThan_Val * 60 ))"
					"d"*)  partialOptStr_NewerThan="-mmin -$(( opt_NewerThan_Val * 60 * 24))"  ## Days can be much less precise than you think due to 'ceiling', so use minutes.
					"w"*)  partialOptStr_NewerThan="-mtime -$(( opt_NewerThan_Val * 7))"  ## Weeks can be much less precise than you think due to 'ceiling', so use days.
				#	"mo")  opt_NewerThan_Val=$(( opt_NewerThan_Val * -30417 / 1000 ))  ## A month is isn't an even # of days; it's 30.417. This gets closer for bigger values of opt_NewerThan_Val.
				#	"y")   opt_NewerThan_Val=$(( opt_NewerThan_Val * -365 ))
				#	*)     _fThrowError "${meName}.${FUNCNAME[0]}(): Unknown unit of time '${opt_NewerThan_Unit}' specified for option '${tmpStr}'."
				#	#"w"*) partialOptStr_NewerThan="-mtime -$(echo "scale=5; ${opt_NewerThan_Val} * 60 * 24" | bc)"  ## Weeks can be much less precise than you think due to 'ceiling', so use days.
				esac
			fi
		fi


		opt_Newest_Val
		opt_Newest_Unit
		opt_After
		opt_Before
		opt_Smallest_Val
		opt_Smallest_Unit
		opt_Biggest_Val
		opt_Biggest_Unit
		opt_PatternsFromFilespec
		opt_FilterMacros
		opt_Filespec_Output_Included
		opt_Filespec_Output_Included_Excluded

	fi

_fdbgEgress "${FUNCNAME[0]}"; }


function fPromptToContinue(){ _fdbgEnter "${FUNCNAME[0]}";
	##	History:
	##		- 20190911 JC: Created template.

	## Constants

	local answer=""
	_fEcho_Clean ""
	read -r -p "Continue? (y/n): " answer
	if [[ "${answer,,}" != "y" ]]; then
		_fEcho "User aborted."
		exit 0
	fi
	_fEcho_ResetBlankCounter

_fdbgEgress "${FUNCNAME[0]}"; }


function fPrint_Copyright_About_Syntax_ThenQuit(){ _fdbgEnter "${FUNCNAME[0]}";
	##	History:
	##		- 20190911 JC: Created template.

	## Constants
	local -r additionalLineOfText="$*"

	fPrint_Copyright
	fPrint_About
	fPrint_Syntax
	if [[ -n "${additionalLineOfText}" ]]; then _fEcho_Clean "Error: ${additionalLineOfText}"; fi
	exit 1

_fdbgEgress "${FUNCNAME[0]}"; }


function fCleanup(){ _fdbgEnter "${FUNCNAME[0]}" "" 0;
	##	Purpose: Invoked once at script end, automatically by script exit/error handlers.
	##	History:
	##		- 20190911 JC: Created template.

	if [[ ${doSkipIntroStuff} -eq 0 ]]; then
		_fEcho_Clean
	fi

_fdbgEgress "${FUNCNAME[0]}" "" 0; }
















function fTemplate(){ _fdbgEnter "${FUNCNAME[0]}";
	#@	Purpose:
	#@	Arguments:
	#@		1 [REQUIRED]:
	#@		2 [optional]:
	#@	Depends on global or parent-scope variable[s] or constant[s]:
	#@
	#@	Modifies global or parent-scope variable[s]:
	#@
	#@	Prints to stdout:
	#@
	#@	Returns via echo to be captured:
	#@
	#@	Other side-effects:
	#@
	#@	Note[s]:
	#@		-
	#@	Example[s]:
	#@		1:
	##	History:
	##		- 20YYMMDD JC: Created.

	## Constants
	local -i -r default_someThing=0

	## Args
	local       arg_someThing="$1"

	## Variables

	## Init

	## Validate

	## Execute
	_fThrowError "${meName}.${FUNCNAME[0]}(): Some error."

_fdbgEgress "${FUNCNAME[0]}"; }


function fUnitTest_ScriptSpecific(){ _fdbgEnter "${FUNCNAME[0]}";

#	_fUnitTest_PrintSectionHeader fPrint_Copyright
#	_fAssert_Eval_AreEqual                 'fMyFunction  "arg1"  "arg2"'    "Expected-Value"
#	_fAssert_AreEqual       fMyFunction  "$(fMyFunction  "arg1"  "arg2" )"  "Expected-Value"



_fdbgEgress "${FUNCNAME[0]}"; }
















##############################################################################
##	Library purpose:
##		- To provide "library" functions to new scripts. But in a way that can be easily shared as single-script solutions.
##			- The old method of sourcing a '0_library_vN', while cleaner in terms of maintaining a whole library of scripts, made publishing/sharing more difficult.
##	Template history:
##		- 20190911 JC: Created.
##		- 20190917 JC: Slight updates and potential bug fixes.
##		- 20190920 JC:
##			- Copied entire contents from ${meName}, which has many improvements to generic & template stuff:
##				- Function logic
##				- Comments (e.g. function documentation)
##				- Expanded argument handling
##				- Structure
##		- 20190923 JC: Converted single brackets to double, for more robusteness.
##		- 20190925 JC:
##			- Added _fPipe_Blake12_Base64URL(), _fPipe_Uuid_Base164URL()
##			- Renamed _Indent() to _fIndent_abs_pipe()
##		- 20190925 JC:
##			- Added functions:
##				fTemplate(), _fUnitTest(), _fAssert_AreEqual(), _fAssert_Eval_AreEqual(), _fStrJustify_byecho()
##				_fdbgEchoVarAndVal(), _fIndent_relative1(), _fStrKeepLeftN_byecho(), _fStrKeepRightN_byecho(), _fToInt_byecho(), _fIndent_rltv_pipe()
##			- Renamed _fIndent1() to _fIndent_abs_pipe()
##			- Added routing logic to detect '--unit-test'
##			- Converted the following functions from modifying named variables, to returning value via echo (due to 'eval' expression causing runtime errors due to unescaped problem characters in output strings):
##				_fEscapeStr_byecho()
##				_fNormalizePath_byecho()
##				_fNormalizeDir_byecho()
##			- _fstrAppend_byref_RISKY()
##				- Added a message to not use it (so it won't break existing scripts if template code updated).
##				- Added _fstrAppend_byglobal() to use instead.
##			- Enhanced _fpStrOps_TempReplacements_byecho(), and _fEscapeStr_byecho()
##			- Added an input argument to _fEchoVarAndVal(): function name.
##			- Added global constant: doDebug=0.
##		- 20190926 JC:
##			- Added debugging functions and variables: _dbgNestLevel, _dbgIndentEachLevelBy, _fdbgEnter(), _fdbgEgress(), _fdbgEcho(), _fPipeAllRawStdout()
##			- Changed everything beginning with "__" to "_"
##			- Added to the end of every "function(){" statement:
##			- Begin to change use of "${variable}" to just "$variable" to quicken dev and improve readability.
##			- Begin use of bash built-in $FUNCNAME.
##			- Appended "1" to every library function so that:
##				- Maintain backward compatibility when copy/pasting everything below a certain line to provide "library" updates to legacy scripts.
##			- Renamed functions that return something by echo, *_byecho
##			- Renamed functions that returns something by global variable, *_byglobal
##		- 20191002 JC: Simplified some "suggested code" in some functions, and commented out others for leaner defaults.
##		- 20191008 JC:
##			- Broke out into TEMPLATE_single-file_1-portion-to-copy_20191008 and TEMPLATE_single-file_2-generic-library.
##				- So that regular updates to template don't have to be copied every time.
##			- Made "escape"-related functions work similar to my python library.
##			- From now on, names of function, and their input & output interface, should NEVER CHANGE.
##				- If that needs to happen, clone the function and append a "2" (or n+1) to the end of the name.
##		- 20200518 JC:
##			- Fixed calls to _fSingleExitPoint() to pass separate args rather than quoted as one, to avoid the catch-all from echoing on ALL exits.
##############################################################################

# shellcheck disable=2016  ## Complains about expressions not expanding in single quotes, which much of _fUnitTest() is based on.
function _fUnitTest(){ _fdbgEnter "${FUNCNAME[0]}";

	_fUnitTest_PrintSectionHeader _fAssert_AreEqual
	_fAssert_AreEqual _fAssert_AreEqual "bob" "bob"
	_fAssert_AreEqual _fAssert_AreEqual "bob" "Bob" 0
	_fAssert_AreEqual _fAssert_AreEqual "bob" "sam" 0


	_fUnitTest_PrintSectionHeader _fStrKeepLeftN_byecho
	_fAssert_Eval_AreEqual '_fStrKeepLeftN_byecho "abcdefghijk"  3'  "abc"
	_fAssert_Eval_AreEqual '_fStrKeepLeftN_byecho "abcdefghijk"  1'  "a"
	_fAssert_Eval_AreEqual '_fStrKeepLeftN_byecho "abcdefghijk"  0'  ""
	_fAssert_Eval_AreEqual '_fStrKeepLeftN_byecho ""            10'  ""
	_fAssert_Eval_AreEqual '_fStrKeepLeftN_byecho ""             0'  ""
	_fAssert_Eval_AreEqual '_fStrKeepLeftN_byecho                 '  ""
	_fAssert_Eval_AreEqual '_fStrKeepLeftN_byecho "abcdefghijk" -1'  ""
	_fAssert_Eval_AreEqual '_fStrKeepLeftN_byecho "abcdefghijk" 99'  "abcdefghijk"


	_fUnitTest_PrintSectionHeader _fStrKeepRightN_byecho
	_fAssert_Eval_AreEqual '_fStrKeepRightN_byecho "abcdefghijk"  3'  "ijk"
	_fAssert_Eval_AreEqual '_fStrKeepRightN_byecho "abcdefghijk"  1'  "k"
	_fAssert_Eval_AreEqual '_fStrKeepRightN_byecho "abcdefghijk"  0'  ""
	_fAssert_Eval_AreEqual '_fStrKeepRightN_byecho ""            10'  ""
	_fAssert_Eval_AreEqual '_fStrKeepRightN_byecho ""             0'  ""
	_fAssert_Eval_AreEqual '_fStrKeepRightN_byecho                 '  ""
	_fAssert_Eval_AreEqual '_fStrKeepRightN_byecho "abcdefghijk" -1'  ""
	_fAssert_Eval_AreEqual '_fStrKeepRightN_byecho "abcdefghijk" 99'  "abcdefghijk"


	_fUnitTest_PrintSectionHeader _fStrJustify_byecho "[shorten]"
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdef"                      "01234567890123456789012345678901"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefg"                     "01234567890123456789012345678901"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefg"                     "012345678901234567890123456789012"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefgh"                    "012345678901234567890123456789012"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefgh"                    "0123456789012345678901234567890123"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghi"                   "0123456789012345678901234567890123"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghi"                   "01234567890123456789012345678901234"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghij"                  "01234567890123456789012345678901234"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghij"                  "012345678901234567890123456789012345"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijk"                 "012345678901234567890123456789012345"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijk"                 "0123456789012345678901234567890123456"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijkl"                "0123456789012345678901234567890123456"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijkl"                "01234567890123456789012345678901234567"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklm"               "01234567890123456789012345678901234567"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklm"               "012345678901234567890123456789012345678"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklmn"              "012345678901234567890123456789012345678"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklmn"              "0123456789012345678901234567890123456789"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklmno"             "0123456789012345678901234567890123456789"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklmno"             "01234567890123456789012345678901234567890"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklmnop"            "01234567890123456789012345678901234567890"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklmnop"            "012345678901234567890123456789012345678901"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopw"           "012345678901234567890123456789012345678901"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopw"           "0123456789012345678901234567890123456789012"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopwx"          "0123456789012345678901234567890123456789012"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopwx"          "01234567890123456789012345678901234567890123"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopwxy"         "01234567890123456789012345678901234567890123"  | _fPipeAllRawStdout
	_fStrJustify_byecho "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopwxy"         "012345678901234567890123456789012345678901234"  | _fPipeAllRawStdout
	_fEcho_ResetBlankCounter


	_fUnitTest_PrintSectionHeader _fStrJustify_byecho "[shorten]"
	_fAssert_AreEqual  _fStrJustify_byecho  "$(_fStrJustify_byecho "Now would be a really good time for all honest good men to come to the aid of their ailing country")"   "Now would be a really good time for al┈┈come to the aid of their ailing country"


	_fUnitTest_PrintSectionHeader _fStrJustify_byecho "[expand]"
	_fAssert_AreEqual  _fStrJustify_byecho  "$(_fStrJustify_byecho                            )"   "..............................................................................."
	_fAssert_AreEqual  _fStrJustify_byecho  "$(_fStrJustify_byecho  "[[["                     )"   "[[[ ..........................................................................."
	_fAssert_AreEqual  _fStrJustify_byecho  "$(_fStrJustify_byecho  ""         "]]]"          )"   "........................................................................... ]]]"
	_fAssert_AreEqual  _fStrJustify_byecho  "$(_fStrJustify_byecho  "[[["      "]]]"          )"   "[[[ ....................................................................... ]]]"
	_fAssert_AreEqual  _fStrJustify_byecho  "$(_fStrJustify_byecho  ""         "hello"        )"  "......................................................................... hello"
	_fAssert_AreEqual  _fStrJustify_byecho  "$(_fStrJustify_byecho  ""         "hello"        )"  "......................................................................... hello"
	_fAssert_AreEqual  _fStrJustify_byecho  "$(_fStrJustify_byecho  "Thing 1"  "hello"        )"  "Thing 1 ................................................................. hello"
	_fAssert_AreEqual  _fStrJustify_byecho  "$(_fStrJustify_byecho  "Thing 1"                 )"  "Thing 1 ......................................................................."
	_fAssert_AreEqual  _fStrJustify_byecho  "$(_fStrJustify_byecho  "Thing 1"  "hello"  0 "=" )"  "Thing 1 ================================================================= hello"
	_fAssert_AreEqual  _fStrJustify_byecho  "$(_fStrJustify_byecho  ""         "hello" 10 "=" )"  "==== hello"
#	_fAssert_AreEqual  _fStrJustify_byecho  "$(_fStrJustify_byecho  "Thing 1"  "hello" 10 "=" )"  "==== hello"


	_fUnitTest_PrintSectionHeader _fToInt_byecho
	_fAssert_Eval_AreEqual '_fToInt_byecho      ""'        0
	_fAssert_Eval_AreEqual '_fToInt_byecho     "b"'        0
	_fAssert_Eval_AreEqual '_fToInt_byecho     "1"'        1
	_fAssert_Eval_AreEqual '_fToInt_byecho   "-99"'      -99
	_fAssert_Eval_AreEqual '_fToInt_byecho 1000000'  1000000


	_fUnitTest_PrintSectionHeader _fConvert_Hex_to_Base64URL_byref
	_fAssert_Eval_AreEqual 'tmpTst=""; _fConvert_Hex_to_Base64URL_byref tmpTst "98d51036-474e-4d31-9588-7ae8cd844c99";                                                                                             echo "${tmpTst}"'  "mNUQNkdOTTGViHrozYRMmQ=="
	_fAssert_Eval_AreEqual 'tmpTst=""; _fConvert_Hex_to_Base64URL_byref tmpTst "e4cfa39a3d37be31c59609e807970799caa68a19bfaa15135f165085e01d41a65ba1e1b146aeb6bd0092b49eac214c103ccfa3a365954bbbe52f74a2b3620c94"; echo "${tmpTst}"'  "5M-jmj03vjHFlgnoB5cHmcqmihm_qhUTXxZQheAdQaZboeGxRq62vQCStJ6sIUwQPM-jo2WVS7vlL3Sis2IMlA=="



	_fUnitTest_PrintSectionHeader _fBlake2_Base64URL_fromString_byref
	_fAssert_Eval_AreEqual 'tmpTst=""; _fBlake2_Base64URL_fromString_byref tmpTst ""; echo "${tmpTst}"'                                                                      "eGoC90IBWQPGxv2FJVLScpEvR0DhWEdhiobiF_cfVBnSXhAxr-5YUxOJZESTTrBLkDpoWxRIt1XVb3Aa_pvizg=="
	_fAssert_Eval_AreEqual 'tmpTst=""; tmpfile="$(mktemp)"; touch "${tmpfile}"; _fBlake2_Base64URL_fromFileContent_byref tmpTst "${tmpfile}"; echo "${tmpTst}"'              "eGoC90IBWQPGxv2FJVLScpEvR0DhWEdhiobiF_cfVBnSXhAxr-5YUxOJZESTTrBLkDpoWxRIt1XVb3Aa_pvizg=="
	_fAssert_Eval_AreEqual 'tmpTst=""; _fBlake2_Base64URL_fromString_byref tmpTst "hello"; echo "${tmpTst}"'                                                                 "5M-jmj03vjHFlgnoB5cHmcqmihm_qhUTXxZQheAdQaZboeGxRq62vQCStJ6sIUwQPM-jo2WVS7vlL3Sis2IMlA=="
	_fAssert_Eval_AreEqual 'tmpTst=""; tmpfile="$(mktemp)"; echo -n "hello" > "${tmpfile}"; _fBlake2_Base64URL_fromFileContent_byref tmpTst "${tmpfile}"; echo "${tmpTst}"'  "5M-jmj03vjHFlgnoB5cHmcqmihm_qhUTXxZQheAdQaZboeGxRq62vQCStJ6sIUwQPM-jo2WVS7vlL3Sis2IMlA=="


	_fUnitTest_PrintSectionHeader _fUUID_Base64URL_byref
	_fAssert_Eval_AreEqual 'tmpTst=""; _fUUID_Base64URL_byref tmpTst; echo "${tmpTst}"'  "(unpredictable)"  0


	fUnitTest_ScriptSpecific
	_fEcho
	_fEcho "Done."


_fdbgEgress "${FUNCNAME[0]}"; }


function _fBlake2_Base64URL_fromString_byref(){ _fdbgEnter "${FUNCNAME[0]}";
	##	Purpose: Generate a base64-URL-encoded Blake2 checksum from an input string.
	##	Input:
	##		1 [REQUIRED]: Variable name that will be populated with result.
	##		2 [REQUIRED]: String to generate checksum from.
	##	Modifies:
	##		Variable specified as first argument.
	##	Examples:
	##		_fBlake2_Base64URL_fromString_byref MyVariable "hello"
	##	History:
	##		- 20190925 JC: Created.

	local -r variableName="$1"
	local -r inputStr="$2"
	local    returnStr=""
	if [[ -z "${variableName}" ]]; then _fThrowError "${meName}.${FUNCNAME[0]}(): No variable specified."; fi
	returnStr="$(echo -n "${inputStr}" | b2sum --binary | grep -iPo "[0-9a-f]+")" #...........................................: Generate Blake2 checksum for input string; For integrity of results, don't eat errors!
	_fConvert_Hex_to_Base64URL_byref returnStr "${returnStr}" #...........................................................: For integrity of results, don't eat errors!  ## For integrity of results, don't eat errors!
	eval "${variableName}=\"${returnStr}\""

_fdbgEgress "${FUNCNAME[0]}"; }


function _fBlake2_Base64URL_fromFileContent_byref(){ _fdbgEnter "${FUNCNAME[0]}";
	##	Purpose: Generate a base64-URL-encoded Blake2 checksum from the contents of a specified filespec.
	##	Input:
	##		1 [REQUIRED]: Variable name that will be populated with result.
	##		2 [REQUIRED]: File specification to generate checksum from content.
	##	Modifies:
	##		Variable specified as first argument.
	##	Examples:
	##		_fBlake2_Base64URL_fromFileContent_byref MyVariable "${HOM$}/Downloads/download.zip"
	##	History:
	##		- 20190925 JC: Created.

	local -r variableName="$1"
	local -r fileSpec="$2"
	local    blake2Checksum=""
	local    returnStr=""
	if [[ -z "${variableName}" ]]; then _fThrowError "${meName}.${FUNCNAME[0]}(): No variable specified."; fi
	if [[ -z "${fileSpec}" ]]; then     _fThrowError "${meName}.${FUNCNAME[0]}(): No filespec specified."; fi
	if [[ ! -f "${fileSpec}" ]]; then   _fThrowError "${meName}.${FUNCNAME[0]}(): Specified file not found: '${fileSpec}'."; fi
	head -c 10 "${fileSpec}" 1>/dev/null  ## Try this in order to error now, if it can't be read
	# shellcheck disable=2002  ## Useless use of cat. This works well though and I don't want to break it for the sake of syntax purity.
	blake2Checksum="$(cat "${fileSpec}" | b2sum --binary | grep -iPo "[0-9a-z]+")" #.......................................: For integrity of results, don't eat errors!
	_fConvert_Hex_to_Base64URL_byref returnStr "${blake2Checksum}" #......................................................: For integrity of results, don't eat errors!
	eval "${variableName}=\"${returnStr}\""

_fdbgEgress "${FUNCNAME[0]}"; }


function _fUUID_Base64URL_byref(){ _fdbgEnter "${FUNCNAME[0]}";
	##	Purpose: Generates a base64-URL-encoded UUID v4 (random).
	##	Input:
	##		1 [REQUIRED]: Variable name that will be populated with result.
	##	Usage examples:
	##		_fUUID_Base164URL MyVar
	##	History:
	##		- 20190925 JC: Created.

	local -r variableName="$1"
	local    returnStr=""
	if [[ -z "${variableName}" ]]; then _fThrowError "${meName}.${FUNCNAME[0]}(): No variable specified."; fi
	returnStr="$(uuid -v 4 )" #............................................................................................: For integrity of results, don't eat errors!
	_fConvert_Hex_to_Base64URL_byref returnStr "${returnStr}" #...........................................................: For integrity of results, don't eat errors!
	eval "${variableName}=\"${returnStr}\""

_fdbgEgress "${FUNCNAME[0]}"; }


function _fConvert_Hex_to_Base64URL_byref(){ _fdbgEnter "${FUNCNAME[0]}";
	##	Purpose:
	##		- Converts a hex string to binary, then binary to base64-URL-encoded string (per per RFC 4648 § 5).
	##		- Ignores dashes (works on UUID strings).
	##	Input:
	##		1 [REQUIRED]: Variable name that will be populated with result.
	##	Usage examples:
	##		_fConvert_Hex_to_Base64URL_byref MyVar "aaff1209"
	##	History:
	##		- 20190925 JC: Created.

	local -r variableName="$1"
	local -r inputStr="$2"
	local returnStr_ch2b=
	if [[ -n "${inputStr}" ]]; then
		if [[ ! ${inputStr,,} =~ ^[\-a-f0-9]+$ ]]; then _fThrowError "${meName}.${FUNCNAME[0]}(): Invalid hexadecimal string: '${inputStr}'."; fi
		returnStr_ch2b="$(echo -n "${inputStr,,}" | xxd -r -p | base64 -w 0)" #........................................: Convert hex to binary, then binary to base64; For integrity of results, don't eat errors!
		returnStr_ch2b="${returnStr_ch2b//+/-}" #......................................................................: Replace "+" with "-", per RFC 4648 § 5
		returnStr_ch2b="${returnStr_ch2b//\//_}" #.....................................................................: Replace "/" with "_", per RFC 4648 § 5
	#	returnStr_ch2b="${returnStr_ch2b//=/}" #.......................................................................: Remove optional base64 padding chars
	fi
	eval "${variableName}=\"${returnStr_ch2b}\""

_fdbgEgress "${FUNCNAME[0]}"; }


function _fToInt_byecho(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;

	##	Purpose: Converts any input to an integer (zero if there's any problem).
	local input="$*"
	local -i retVal=0
	if [[ -n "${input}" ]]; then
		if [[ $input =~ ^-?[0-9]+$ ]]; then
			retVal=$input 2>/dev/null || true
		fi
	fi

	# shellcheck disable=2086  ## Unquoted return value. Which is part of the the point for this function.
	echo $retVal

_fdbgEgress "${FUNCNAME[0]}" "" 1; }


function _fStrSearchAndReplace_byecho(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;
	##	Purpose: For every match in a string, substitutes a replacement.
	##	Input:
	##		- Source string.
	##		- Search substring.
	##		- Replacement substring.
	##	Returns:
	##		Modified string via echo. Capture with: MyVariable="$(_MyFunction "MyArg1" ...etc...)"
	##	Notes:
	##		- Case-sensitve
	##		- Performons only ONE pass - can't get stuck in a loop.
	##		- Uses sed and tr for more robustness.
	##	TODO:
	##		Make sure can handle random strings with double quotes in them (as opposed to singular double quotes).
	##	History:
	##		- 20160906 JC: Rewrote from scratch to:
	##			- Only make one pass.
	##			- Use 'sed' instead of bash variable expansion, for more robust handling of:
	##				- Double quotes.
	##				- Escaped characters such as \n.
	##		- 20170308 JC: Use bash variable expansion to bypass frustrating sed time-sink / bug.
	##		- 20190920 JC: Improved function header comments.

	## Input
	local vlsString="$1"
	local vlsFind="$2"
	local vlsReplace="$3"

	## Temp replacements to avoid problems and trades speed for robustness
	vlsString="$(_fLegacy_pStrOps_TempReplacements_byecho  "forward" "${vlsString}")"
	vlsFind="$(_fLegacy_pStrOps_TempReplacements_byecho    "forward" "${vlsFind}")"
	vlsReplace="$(_fLegacy_pStrOps_TempReplacements_byecho "forward" "${vlsReplace}")"

	## Do the replacing
	# shellcheck disable=2116  ## False positive
	vlsString="$(echo "${vlsString//${vlsFind}/${vlsReplace}}")"

	## Reverse temp replacements
	vlsString="$(_fLegacy_pStrOps_TempReplacements_byecho "reverse" "${vlsString}")"

	echo -e "${vlsString}"

_fdbgEgress "${FUNCNAME[0]}" "" 1; }


function fEscapeStr_byecho(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;
	#@	Purpose:
	#@		- Escapes a string so that quotes, asterisks, etc. won't screw up SQL, Windows filenames, eval, etc.
	#@		- Many of those things are valid Linux filenames but will break other stuff.
	#@	Arg .......: A string to escape.
	#@	Echos .....: Updated string.
	#@	Example ...: MyVariable="$(fEscapeStr_byecho "Some input string that might have wonky characters that break filenames, SQL, or eval")"
	#@	History:
	#@		- 20191008 JC: Created by copying and modifying fLegacy_escapeOrUnStStr_byecho().
	local valStr="$1"
	valStr="$( echo -e "${valStr}" | sed ':a;N;$!ba;s/\n/⌁▸newline◂⌁/g'     2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed 's*\"*⌁▸dquote◂⌁*g'                2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed "s/'/⌁▸squote◂⌁/g"                 2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed 's/`/⌁▸backtick◂⌁/g'               2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed 's*\t*⌁▸tab◂⌁*g'                   2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed 's*\\*⌁▸backslash◂⌁*g'             2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed "s/\*/⌁▸asterisk◂⌁/g"              2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed "s/\?/⌁▸questionmark◂⌁/g"          2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed "s/|/⌁▸pipe◂⌁/g"                   2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed "s/</⌁▸lthan◂⌁/g"                  2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed "s/>/⌁▸gthan◂⌁/g"                  2>/dev/null || true)"
	# shellcheck disable=2016  ## False positive on non-expanding variable
	valStr="$( echo -e "${valStr}" | sed 's/\$(/⌁▸dollarlparen◂⌁/g'         2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed 's/\$/⌁▸dollarl◂⌁/g'               2>/dev/null || true)"
	echo "${valStr}"
_fdbgEgress "${FUNCNAME[0]}" "" 1; }


function fUnEscapeStr_byecho(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;
	#@	Purpose:
	#@		- Escapes a string so that quotes, asterisks, etc. won't screw up SQL, Windows filenames, eval, etc.
	#@		- Many of those things are valid Linux filenames but will break other stuff.
	#@	Arg .......: A string to undo the effects of fEscapeStr_byecho().
	#@	Echos .....: Updated string.
	#@	History:
	#@		- 20191008 JC: Created by copying and modifying fLegacy_escapeOrUnStStr_byecho().
	local      valStr="$1"
	valStr="$( echo -e "${valStr}" | sed 's*⌁▸newline◂⌁*\n*g'               2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed 's*⌁▸dquote◂⌁*\"*g'                2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed "s/⌁▸squote◂⌁/'/g"                 2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed 's/⌁▸backtick◂⌁/`/g'               2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed 's*⌁▸tab◂⌁*\t*g'                   2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed 's*⌁▸backslash◂⌁*\\*g'             2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed "s/⌁▸asterisk◂⌁/\*/g"              2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed "s/⌁▸questionmark◂⌁/\?/g"          2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed "s/⌁▸pipe◂⌁/|/g"                   2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed "s/⌁▸lthan◂⌁/</g"                  2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed "s/⌁▸gthan◂⌁/>/g"                  2>/dev/null || true)"
	# shellcheck disable=2016  ## False positive on non-expanding variable
	valStr="$( echo -e "${valStr}" | sed 's/⌁▸dollarlparen◂⌁/\$(/g'         2>/dev/null || true)"
	valStr="$( echo -e "${valStr}" | sed 's/⌁▸dollarl◂⌁/\$/g'               2>/dev/null || true)"
	echo "${valStr}"
_fdbgEgress "${FUNCNAME[0]}" "" 1; }


function _fIndent_abs_pipe(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;
	##	Purpose: Meant to be used on right side of pipe, to first unindent stdout, then indent to specified number of spaces.
	##	Input (besides stout):
	##		1 [REQUIRED]: Number of spaces to indent.
	##	Output: stdout
	##	Usage examples
	##		- ls -lA . | _fIndent_abs_pipe 2
	##	History:
	##		- 20190903 JC: Created.
	##		- 20190920 JC: Improved function header comments.

	sed -e 's/^[ \t]*//' | sed "s/^/$(printf "%${1}s")/"

_fdbgEgress "${FUNCNAME[0]}" "" 1; }


function _fIndent_rltv_pipe(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;
	##	Purpose: Meant to be used on right side of pipe, to first unindent stdout, then indent to specified number of spaces.
	##	Input (besides stout):
	##		1 [REQUIRED]: Number of spaces to indent.
	##	Output: stdout
	##	Usage examples
	##		- ls -lA . | _fIndent_rltv_pipe 2
	##	History:
	##		- 20190925 JC: Created by copying _fPipe_Indent_abs_absolute1

	sed "s/^/$(printf "%${1}s")/"

_fdbgEgress "${FUNCNAME[0]}" "" 1; }


function _fStrJustify_byecho(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;
	#@	Purpose:
	#@		- Left and right-justifies one or two strings.
	##		- Also doesn't allow the final output to go over specified columns. If it does, the minimum padding witdh is inserted in between a result split in the middle.
	#@	Arguments:
	#@		1 [optional]: String on left
	#@		2 [optional]: String on right
	#@		3 [optional]: Maximum width (default:79)
	#@		4 [optional]: String to pad in between with, usually just one character (default ".")
	#@	Returns via echo: Right-justified string
	##	History:
	##		- 20190925 JC: Created.
	##	TODO:
	##		- Figure out a better solution for too-long strings, other than cutting the middle out of the LEFT string.
	##		- Solution must:
	##			- Put "┈" in the middle (rather than just the left as currently), if both strings are > 1/2 max.
	##			- If any stirng is too long

	## Constants
	local -r -i default_rightmostCol=79
	local -r    default_padStr="."
	local -r    splitStrIndicatorIfTooLong="┈┈"

	## Args
	local       leftStr="$1"
	local       rightStr="$2"
	local    -i maxWidth=$(_fToInt_byecho "$3")
	local       padStr="$4"

	## Variables
	local       printfCommand=""
	local       wholePad=""
#	local    -i extraPlacesToRemove=0
	local    -i totalCharsFromPadToRemove=0
	local    -i maxHypotheticalWidth=0
	local    -i lenLeftPart=0
	local    -i lenRightPart=0
	local       tmpStr=""
	local       tmpPadStr=""
	local       returnStr=""

	## Init; default values
	if [[ -z "${maxWidth}" ]] || [[ ! ${maxWidth} =~ [0-9]+ ]] || [[ "${maxWidth}" == "0" ]]; then maxWidth="${default_rightmostCol}"; fi
	if [[ -z "${maxWidth}" ]] || [[ ! ${maxWidth} =~ [0-9]+ ]] || [[ "${maxWidth}" == "0" ]]; then maxWidth="${default_rightmostCol}"; fi
	if [[ -z "${padStr}" ]]; then padStr="${default_padStr}"; fi

	## Figure out if string is too long
	maxHypotheticalWidth=$((${#leftStr} + 1 + ${#rightStr}))
	tooLongBy=$((maxHypotheticalWidth - maxWidth))

#_fEchoVarAndVal leftStr
#_fEchoVarAndVal rightStr
#_fEchoVarAndVal maxHypotheticalWidth
#_fEchoVarAndVal tooLongBy

	if [[ ${tooLongBy} -gt 0 ]]; then

		## Update these values for inclusion of $splitStrIndicatorIfTooLong
		maxHypotheticalWidth=$((${#leftStr} + ${#splitStrIndicatorIfTooLong} + ${#rightStr}))
		tooLongBy=$((maxHypotheticalWidth - maxWidth))
		if [[ $tooLongBy -le 0 ]]; then tooLongBy=0; fi

		## The total output will be too long. Split the longest string in half and put $splitStrIndicatorIfTooLong in between.
		if [[ ${#rightStr} -gt ${#leftStr} ]]; then  ## If equal, left
			tmpStr="${rightStr}"
		else
			tmpStr="${leftStr}"
		fi

		## Split the longest string in half, and only for that longest string, hack off some of the right part of left half, and some of the left part of right half
			## Split the longest string in half. Round first half up; but Bash integer math always rounds down; this trick rounds up.
				#### result=$(( (numerator  + (denominator - 1) / denomonator) ))
				lenLeftPart=$(( (${#tmpStr} + 1               ) / 2            ))
				    ##Eg 13=$(( (25         + 1               ) / 2            ))
				## Now trim half of the overage off from left half, also rounding up (which evens it out)
				lenLeftPart=$(( lenLeftPart - ((tooLongBy+1)/2) ))
			## Round second half down; Bash always does this anyway
				## (( result=$(( (numerator  / denomonator) ))
				lenRightPart=$(( (${#tmpStr} / 2          ) ))
				   ##Eg   12=$(( (25         / 2          ) ))
				## Now trim half of the overage off from left half, also rounding up (which evens it out)
				lenRightPart=$(( lenRightPart - (tooLongBy/2) ))
			## Build the splint string
			tmpStr="$(_fStrKeepLeftN_byecho "${tmpStr}" ${lenLeftPart})${splitStrIndicatorIfTooLong}$(_fStrKeepRightN_byecho "${tmpStr}" ${lenRightPart})"

		## Replace longest string with the split result
		if [[ ${#rightStr} -gt ${#leftStr} ]]; then
			rightStr="${tmpStr}"
		else
			leftStr="${tmpStr}"
		fi
	fi

#_fEchoVarAndVal leftStr
#_fEchoVarAndVal rightStr

	printfCommand="printf '${padStr}%.0s' {1..${maxWidth}}"
	wholePad="$(eval "${printfCommand}")"
	if [[ -n "${leftStr}" ]]   && [[ $tooLongBy -le 0 ]]; then leftStr="${leftStr} "; fi
	if [[ -n "${rightStr}" ]]  && [[ $tooLongBy -le 0 ]]; then rightStr=" ${rightStr}"; fi
	totalCharsFromPadToRemove=$((${#leftStr} + ${#rightStr}))
	tmpPadStr="${wholePad:$totalCharsFromPadToRemove}"
	if [[ -z "${tmpPadStr}" ]] && [[ -n "${leftStr}" ]] && [[ -n "${rightStr}" ]]; then
		tmpPadStr=" "
	fi
	returnStr="${leftStr}${tmpPadStr}${rightStr}"

	## This logic isn't always correct, and isn't even really a good overall idea (at least for too long strings); so just in case, crop to max chars len
	returnStr="$(_fStrKeepLeftN_byecho "${returnStr}" ${maxWidth})"

#_fEchoVarAndVal padStr
#_fEchoVarAndVal maxWidth
#_fEchoVarAndVal wholePad
#_fEchoVarAndVal totalCharsFromPadToRemove
#_fEchoVarAndVal leftStr
#_fEchoVarAndVal tmpPadStr
#_fEchoVarAndVal rightStr
#_fEchoVarAndVal returnStr
#return

	echo "${returnStr}"

_fdbgEgress "${FUNCNAME[0]}" "" 1; }


function _fStrKeepLeftN_byecho(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;
	##	History:
	##		- 20190925 JC: Created.

	local -r    inputStr="$1"
	local    -i numberOfCharacters=$(_fToInt_byecho "$2")
	local       returnVal=""
	if [[ ${numberOfCharacters} -le 0 ]]; then
		returnVal=""
	elif [[ ${numberOfCharacters} -ge ${#inputStr} ]]; then
		returnVal="${inputStr}"
	else
		returnVal="${inputStr::${numberOfCharacters}}"
	fi
	echo "${returnVal}"

_fdbgEgress "${FUNCNAME[0]}" "" 1; }


function _fStrKeepRightN_byecho(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;
	##	History:
	##		- 20190925 JC: Created.

	local -r    inputStr="$1"
	local    -i numberOfCharacters=$(_fToInt_byecho "$2")
	local       returnVal=""
	if [[ ${numberOfCharacters} -le 0 ]]; then
		returnVal=""
	elif [[ ${numberOfCharacters} -ge ${#inputStr} ]]; then
		returnVal="${inputStr}"
	else
		returnVal="${inputStr:(-${numberOfCharacters})}"
	fi
	echo "${returnVal}"

_fdbgEgress "${FUNCNAME[0]}" "" 1; }


function _fStrTrim_byecho(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;
	##	Purpose: Strip off leading and trailing whitespace from a string.
	##	Input:
	##		1 [REQUIRED]: String to trim.
	##	Returns:
	##		Modified string via echo. Capture with: MyVariable="$(_MyFunction "MyArg1" ...etc...)"
	##	History:
	##		- 20190826 JC: Created by copying from 0_library_v2.
	##		- 20190920 JC: Improved function header comments.

	local inputStr="$*"
	if [[ -n "${inputStr}" ]]; then
		outputStr="$(echo -e "${inputStr}" | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//' 2>/dev/null || true)"
	fi
	echo -n "${outputStr}"

_fdbgEgress "${FUNCNAME[0]}" "" 1; }


function _fStrNormalize_byecho(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;
	##	Purpose:
	##		- Strips leading and trailing spaces from string.
	##		- Changes all whitespace inside a string to single spaces.
	##	Input:
	##		1 [REQUIRED]: String to normalize
	##	Returns:
	##		Modified string via echo. Capture with: MyVariable="$(_MyFunction "MyArg1" ...etc...)"
	##	References:
	##		- https://unix.stackexchange.com/a/205854
	##	History:
	##		- 20190701 JC: Created
	##		- 20190724 JC: Didn't work on newlines. Fixed.
	##		- 20190920 JC: Improved function header comments.

	local argStr="$*"
	argStr="$(echo -e "${argStr}")" #.................................................................. Convert \n and \t to real newlines, etc.
	argStr="${argStr//$'\n'/ }" #...................................................................... Convert newlines to spaces
	argStr="${argStr//$'\t'/ }" #...................................................................... Convert tabs to spaces
	argStr="$(echo "${argStr}" | awk '{$1=$1};1' 2>/dev/null || true)" #............................... Collapse multiple spaces to one and trim
	argStr="$(echo "${argStr}" | sed 's/^[[:blank:]]*//;s/[[:blank:]]*$//' 2>/dev/null || true)" #..... Additional trim
	echo "${argStr}"

_fdbgEgress "${FUNCNAME[0]}" "" 1; }


declare _fstrAppend_byglobal_val=""
function _fstrAppend_byglobal(){ _fdbgEnter "${FUNCNAME[0]}";
	##	Purpose:
	##		- Appends arg1 to the string value in global variable _fstrAppend_byglobal_val,
	##		  with arg2 as a delimiter if necessary.
	##		- Continues whether or not value in arg1 is empty, or arg3 is empty.
	##		- Pros and cons of this approach (modifying a dedicated global variable):
	##			- Pro: Is more efficient for highly iterative uses, than the multiple unnecessary str copies of the "echo" method.
	##			- Pro: Won't error on some characters such as the "eval" method.
	##			- Con: A single global variable means you can't call this to build more than one string at a time.
	##			- Con: Is inelegant.
	##	Input:
	##		1 [optional]: String to first append with, if existing contents aren't empty. (e.g. space, comma, newline)
	##		2 [optional]: String to append.
	##	Modifies:
	##		_fstrAppend_byglobal_val
	##	Examples:
	##		_fstrAppend_byglobal_val=""  ##....................... Clear _fstrAppend_byglobal_val
	##		_fstrAppend_byglobal "\n"  "First in the list!"  ##... Append a string
	##		_fstrAppend_byglobal "\n"  "Next in the list!"  ##.... Append another string
	##		MyStr="${_fstrAppend_byglobal_val}"  ##............... Copy result to local variable
	##	History:
	##		- 20190826 JC: Created by copying from 0_library_v2.
	##		- 20190920 JC: Added error checking of variable name.
	##		- 20190926 JC: Copied _fstrAppend_1() and converted from "eval" to "global" approach, due to errors.

	## Constants

	## Args
	local -r appendFirstIfExistingNotEmpty="$1"
	local -r appendStr="$2"

	## Append (written this way to be a little faster for highly iterative uses
	if [[ -z "${_fstrAppend_byglobal_val}" ]]; then
		_fstrAppend_byglobal_val="${appendStr}"
	else
		_fstrAppend_byglobal_val="${_fstrAppend_byglobal_val}${appendFirstIfExistingNotEmpty}${appendStr}"
	fi

_fdbgEgress "${FUNCNAME[0]}"; }


function _fstrAppend_byref_RISKY(){ _fdbgEnter "${FUNCNAME[0]}";
	##	Purpose:
	##		- Exists for legacy purposes. Don't use it, it's prone to barfing on some input due to "eval".
	##		- Use _fstrAppend_byglobal() instead.
	##	Input:
	##		1 [REQUIRED]: Variable name to populate.
	##		2 [optional]: String to first append with, if existing contents aren't empty. (e.g. space, comma, newline)
	##		3 [optional]: String to append.
	##	Modifies:
	##		Variable specified by name as arg1.
	##	Examples:
	##		_fstrAppend_byglobal  MyVariable  "\n"  "First in the list!"  ##... Append a string
	##		_fstrAppend_byglobal  MyVariable  "\n"  "Next in the list!"  ##.... Append another string
	##	History:
	##		- 20190826 JC: Created by copying from 0_library_v2.
	##		- 20190920 JC: Added error checking of variable name.

	_fEcho_Clean "${meName}.${FUNCNAME[0]}(): This function is depreciated due to reliance on 'eval'. Refactor to use _fstrAppend_byglobal()."

	## Args
	local -r variableName="$1"
	local -r appendFirstIfExistingNotEmpty="$2"
	local -r appendStr="$3"

	## Validate
	if [[ -z "${variableName}" ]]; then _fThrowError "${meName}.${FUNCNAME[0]}(): No variable specified."; fi

	## Variables
	local valStr="${!variableName}"

	## Append to variable who's name is stored in $variableName
	if [[ -n "${valStr}" ]]; then valStr="${valStr}${appendFirstIfExistingNotEmpty}"; fi
	valStr="${valStr}${appendStr}"
	eval "${variableName}=\"${valStr}\""

_fdbgEgress "${FUNCNAME[0]}"; }


function _fNormalizeDir_byecho(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;
	##	Purpose:
	##		- Given a folder path as a string, normalizes it.
	##		- It doesn't have to exist already.
	##		- And makes sure it has exactly one ending "/" (even if root).
	##	Input:
	##		1 [REQUIRED]: Folder path.
	##	Output:
	##		Modified value via echo.
	##	Examples:
	##		MyVariable="$(_fNormalizePath_byecho "/etc /x")"
	##	History:
	##		- 20190923 JC: Created.
	##		- 20190925 JC: Changed from 'byref' (eval) to 'byval' (echo), because eval barfs on many valid filename characters (e.g. "`", "$(", etc.)

	local strVal="$1"
	strVal="$(_fNormalizePath_byecho "${strVal}")"
	strVal="${strVal}/"
	strVal="${strVal//\/\//\/}"  #.... Replace two slashes with one, just in case
	echo "${strVal}"

_fdbgEgress "${FUNCNAME[0]}" "" 1; }


function _fNormalizePath_byecho(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;
	##	Purpose:
	##		- Given a file or folder path as a string, normalizes it.
	##		- It doesn't have to exist already.
	##		- And makes sure it has exactly one ending "/" (even if root).
	##	Input:
	##		1 [REQUIRED]: Folder path.
	##	Output:
	##		Modified value via echo.
	##	Examples:
	##		MyVariable="$(_fNormalizePath_byecho "/etc/x.rdp")"
	##	History:
	##		- 20190826 JC: Created by copying from 0_library_v2.
	##		- 20190925 JC: Changed from 'byref' (eval) to 'byval' (echo), because eval barfs on many valid filename characters (e.g. "`", "$(", etc.)

	local strVal="$1"
	local loop_PreviousStr=""
	# shellcheck disable=2001  ## Sometimes purposely using sed when builtin doesn't work for specific usage.
	while [[ "${strVal}" != "${loop_PreviousStr}" ]]; do
		loop_PreviousStr="${strVal}"
		strVal=${strVal//$'\n'/ } #............................................................. Replace newlines
		strVal=${strVal//$'\t'/ } #............................................................. Replace tabs with spaces
		strVal="$(echo "${strVal}" | sed 's#\\#/#g' 2>/dev/null || true)" #..................... Convert backslashes to forward slashes
		strVal="$(echo "${strVal}" | sed 's#/ #/#g' | sed 's# /#/#g' 2>/dev/null || true)" #.... Remove space before and after slashes
		strVal="$(echo "${strVal}" | sed 's#//#/#g' 2>/dev/null || true)" #..................... Replace two backslashes with one
		strVal="${strVal%/}" #.................................................................. Trim trailing slash
		strVal="$(_fStrTrim_byecho "${strVal}")" #.................................................... Trim leading and trailing whitespace
	done
	echo "${strVal}"

_fdbgEgress "${FUNCNAME[0]}" "" 1; }


function _fMustBeInPath(){ _fdbgEnter "${FUNCNAME[0]}";
	##	History:
	##		- 20190826 JC: Created by copying from 0_library_v2.

	local -r programToCheckForInPath="$1"
	if [[ -z "${programToCheckForInPath}" ]]; then
		_fThrowError "_fMustBeInPath(): Not program specified."
	elif [[ -z "$(command -v "${programToCheckForInPath}" 2>/dev/null || true)" ]]; then
		_fThrowError "Not found in path: ${programToCheckForInPath}"
	fi

_fdbgEgress "${FUNCNAME[0]}"; }

function _fIsNum_v2(){ :;
	##	20141117 JC: Created.
	##	20200828 JC: Return 0 or 1 instead of "true", "false" string.
	if [[ "$1" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
		echo 1
	else
		echo 0
	fi
}

function _fIsInt(){ :;
	##	20141117 JC: Created.
	##	20200828 JC: Return 0 or 1 instead of "true", "false" string.
	if [[ "$1" =~ ^-?[0-9]+$ ]]; then
		echo 1
	else
		echo 0
	fi
}

function fIsString_PackedArgs(){ :;
	##	Purpose:
	##		Returns "true" if the string is some result of fPackArgs().
	##	Input:
	##		Anything or nothing.
	##	History:
	##		- 20171217 JC: Created.

	## Variables.
	local vlsInput="$*"
	local vlbReturn="false"

	if [[ "${vlsInput}" =~ ^⦃packedargs-begin⦄.*⦃packedargs-end⦄$ ]]; then :;
		local vlbReturn="true"
	fi

	echo "${vlbReturn}"

}


##----------------------------------------------------------------------------------------------------
function fPackedArgs_GetCount(){ :;
	##	Purpose:
	##		Given a packedargs string, returns the number of arguments.
	##	Input:
	##		Some result of fPackArgs()
	##	History:
	##		- 20171217 JC: Created.

	## Variables.
	local vlsInput="$*"
	local vlwReturnCount=0
	local vlsItem_Unpacked=""

	if [[ "${vlsInput}" =~ ^⦃packedargs-begin⦄.*⦃packedargs-end⦄$ ]]; then :;

		## Strip wrapper off
		vlsInput="$(echo "${vlsInput}" | sed "s/⦃packedargs-begin⦄//g")"
		vlsInput="$(echo "${vlsInput}" | sed "s/⦃packedargs-end⦄//g")"

		## Parse into array on "_"
		local vlsPrev=$IFS
		#IFS="_"
		IFS="☊"  ## 20190615 JC: Changed from _ to ☊ because _ was turning up in unpacked strings somehow. Not sure if this will fix it.
			# shellcheck disable=2206  ## Must disable complaining about quotes. Next statemnet doesn't work with quotes.
			local -a vlsArray=(${vlsInput})
		IFS="${vlsPrev}"

		## Return array length, which is the count of arguments
		vlwReturnCount=${#vlsArray[@]}
		if [[ $(_fIsInt "${vlwReturnCount}") -eq 0 ]]; then :;
			vlwReturnCount=0
		fi

		## Check for empty array
		if [[ ${vlwReturnCount} -eq 1 ]]; then :;
			if [[ "${vlsArray[0]}" == "" ]]; then :;
				vlwReturnCount=0
			fi
		fi

		## We should never have a single element of "⦃empty⦄", unless explicitly passed to fPackArgs().
		#if [[ vlwReturnCount -eq 1 ]]; then :;
		#	if [[ "${vlsArray[0]}" == "⦃empty⦄" ]]; then :;
		#		vlwReturnCount=0
		#	fi
		#fi

	fi

	echo ${vlwReturnCount}

}


##----------------------------------------------------------------------------------------------------
function fUnpackArg_Number(){ :;
	##	Purpose:
	##		Given a packedargs string, and an argument number, returns a value.
	##		withouting getting fubar'ed by spaces and quotes.
	##	Input:
	##		1 [REQUIRED]: A packed arg string.
	##		2 [REQUIRED]: Integer >0 and < fPackedArgs_GetCount()
	##	History:
	##		- 20171217 JC: Created.

	## Input
	local vlsInput="$1"
	local vlwArgNum=$2

	## Variables
	local vlsReturn=""
	local vlsItem_Packed=""
	local vlsItem_Unpacked=""
	local vlwArgCount=0
	local vlwGetArrayIndex=0

	## Validation variables
	local vlbIsValid_PackedArg="false"
	local vlbIsValid_ArgNum="false"

	## Validate part 1/2
	if [[ -n "${vlsInput}" ]]; then :;
		if [[ "${vlsInput}" =~ ^⦃packedargs-begin⦄.*⦃packedargs-end⦄$ ]]; then :;
			vlbIsValid_PackedArg="true"
			vlwArgCount=$(fPackedArgs_GetCount "${vlsInput}")
			if [[ $(_fIsInt "${vlwArgNum}") -eq 1 ]]; then :;
				if [[ ${vlwArgNum} -gt 0 ]]; then :;
					if [[ ${vlwArgNum} -le ${vlwArgCount} ]]; then :;
						vlbIsValid_ArgNum="true"
					fi
				fi
			fi
		fi
	fi

	## Validate part 2/2
	if [[ "${vlbIsValid_PackedArg}" != "true" ]]; then :;
		vlsReturn=""
		#fThrowError "Input is not a packed args string."
	elif [[ "${vlbIsValid_ArgNum}" != "true" ]]; then :;
		vlsReturn=""
		#fThrowError "Argument number (second input) must be >0 and <[argument count]."
	else :;

		## Strip wrapper off
		vlsInput="$(echo "${vlsInput}" | sed "s/⦃packedargs-begin⦄//g")"
		vlsInput="$(echo "${vlsInput}" | sed "s/⦃packedargs-end⦄//g")"

		## Parse into array on "_"
		local vlsPrev=$IFS
		#IFS="_"
		IFS="☊"  ## 20190615 JC: Changed from _ to ☊ because _ was turning up in unpacked strings somehow. Not sure if this will fix it.
			# shellcheck disable=2206  ## Must disable complaining about quotes. Next statemnet doesn't work with quotes.
			local -a vlsArray=(${vlsInput})
		IFS="${vlsPrev}"

		## Calculate the array index, from arg num
		vlwGetArrayIndex=$(( ${vlwArgNum} - 1 ))

		## Get the value stored in the specified array index
		vlsItem_Packed="${vlsArray[$vlwGetArrayIndex]}"

		## Unpack
		vlsItem_Unpacked="$(fUnpackString "${vlsItem_Packed}")"

		## Set return value
		vlsReturn="${vlsItem_Unpacked}"

	fi

	echo "${vlsReturn}"

}


##----------------------------------------------------------------------------------------------------
function fPackArgs(){ :;
	##	Purpose:
	##		Packs up arguments to allow passing around to functions and scripts,
	##		withouting getting fubar'ed by spaces and quotes.
	##	Input:
	##		Arguments. Can contain spaces, single quotes, double quotes, etc.
	##	Returns via echo:
	##		A packed string that can be safely passed around without getting munged.
	##	History:
	##		- 20161003 JC (0_library): Created.
	##		- 20161003 JC (0_library_v1):
	##			- Renamed from fArgs_Pack() to fPackString().
	##			- Updated "created" date from probably erroneous 2006, to 2016.
	##			- Updated comments.
	##			- Added outer "if" statement to catch null input.
	##		- 20171217 JC (0_library_v2):
	##			- Refactored.
	##			- Add packing header during packing process.
	##			- Check for packing header before packing, to avoid packing more than once.
	##			- Allow for $clwMaxEmptyArgsBeforeBail successive empty values before breaking

	## Constants
	local clwMaxEmptyArgsBeforeBail=8

	## Variables
	local vlsInput="$*"
	local vlsReturn=""
	local vlsCurrentArg=""
	local vlsCurrentArg_Encoded=""
	local vlsEncoded_Final=""
	local vlsEncoded_Provisional=""
	local vlwCount_EmptyArgs=0

	## Debug
	#fEcho_VariableAndValue clwMaxEmptyArgsBeforeBail
	#fEcho_VariableAndValue vlsInput
	#fEcho_VariableAndValue vlsReturn
	#fEcho_VariableAndValue vlsCurrentArg
	#fEcho_VariableAndValue vlsCurrentArg_Encoded
	#fEcho_VariableAndValue vlsEncoded_Final
	#fEcho_VariableAndValue vlsEncoded_Provisional
	#fEcho_VariableAndValue vlwCount_EmptyArgs

	if [[ "${vlsInput}" =~ ^⦃packedargs-begin⦄.*⦃packedargs-end⦄$ ]]; then :;

		## Return already packed input
		vlsReturn="${vlsInput}"

	else :;

		if [[ -z "${vlsInput}" ]]; then :;
			#vlsReturn="⦃empty⦄"  ## Caused a bug. An actual empty set works.
			vlsReturn=""
		else :;
			while [ $vlwCount_EmptyArgs -lt $clwMaxEmptyArgsBeforeBail ]; do

				## Get the first or next value off the args stack
				fDefineTrap_Error_Ignore
					vlsCurrentArg="$1"; shift; true
				fDefineTrap_Error_Fatal

				## Debug
				#fEcho_VariableAndValue vlsCurrentArg

				## Encode
				vlsCurrentArg_Encoded="$(fPackString "${vlsCurrentArg}")"

				## Debug
				#fEcho_VariableAndValue vlsCurrentArg_Encoded

				## Build provisional result
				if [[ -n "${vlsEncoded_Provisional}" ]]; then vlsEncoded_Provisional="${vlsEncoded_Provisional}☊"; fi  ## 20190615 JC: Changed from _ to ☊ because _ was turning up in unpacked strings somehow. Not sure if this will fix it.
				vlsEncoded_Provisional="${vlsEncoded_Provisional}${vlsCurrentArg_Encoded}"

				## Debug
				#fEcho_VariableAndValue vlsEncoded_Provisional

				## Handle if current arg is or isn't empty
				if [[ -z "${vlsCurrentArg}" ]]; then :;
					## Increment sucessive empty counter.
					vlwCount_EmptyArgs=$((vlwCount_EmptyArgs+1))
				else :;
					## Not empty: Set permanent return string (which may make previous empty args part of permanent return).
					vlsEncoded_Final="${vlsEncoded_Provisional}"
					vlwCount_EmptyArgs=0
				fi

				## Debug
				#fEcho_VariableAndValue vlwCount_EmptyArgs

			done

			vlsReturn="${vlsEncoded_Final}"
		fi

		## Wrap
		vlsReturn="⦃packedargs-begin⦄${vlsReturn}⦃packedargs-end⦄"

	fi

	echo "${vlsReturn}"

}


##----------------------------------------------------------------------------------------------------
function fUnpackArgs(){ :;
	##	Purpose:
	##		Unpacks args previously packed with fPackArg(), into its original string.
	##	Arguments:
	##		- 1 [optional]: Packed arguments string originally generated by fPackArgs().
	##	Returns via echo:
	##		- Original string, which due to the original reason for packing and unpacking, may not
	##		  result in full fidelity. [Better to use something like fUnpackArgs_ToArrayPtr().]
	##	History:
	##		- 20161003 JC (0_library): Created.
	##		- 20161003 JC (0_library_v1):
	##			- Renamed from fArgs_Unpack() to fUnpackString().
	##			- Updated "created" date from probably erroneous 2006, to 2016.
	##			- Updated comments.
	##			- Added outer "if" statement to catch null input.
	##		- 20171217 JC (0_library_v2):
	##			- Refactored.
	##			- Check for packing header before unpacking, to avoid unpacking a non-packed args.
	##			- Remove packing header.

	## Variables.
	local vlsInput="$*"
	local vlsReturn=""
	local vlsItem_Unpacked=""

	if [[ "${vlsInput}" =~ ^⦃packedargs-begin⦄.*⦃packedargs-end⦄$ ]]; then :;

		## Strip wrapper off
		vlsInput="$(echo "${vlsInput}" | sed "s/⦃packedargs-begin⦄//g")"
		vlsInput="$(echo "${vlsInput}" | sed "s/⦃packedargs-end⦄//g")"

		## Parse into array on "☊"
		local vlsPrev=$IFS
		IFS="☊"  ## 20190615 JC: Changed from _ to ☊ because _ was turning up in unpacked strings somehow. Not sure if this will fix it.
			# shellcheck disable=2206  ## Must disable complaining about quotes. Next statemnet doesn't work with quotes.
			local -a vlsArray=(${vlsInput})
		IFS="${vlsPrev}"

		## Loop through array
		for vlsItem in "${vlsArray[@]}"; do

			## Debug
			#fEcho_VariableAndValue vlsItem

			## Unpack item
			vlsItem_Unpacked="$(fUnpackString "${vlsItem}")"

			## Add item to return string
			if [[ -n "${vlsReturn}" ]]; then vlsReturn="${vlsReturn} "; fi
			vlsReturn="${vlsReturn}'${vlsItem_Unpacked}'"

		done

	else :;

		## Return already unpacked input
		vlsReturn="${vlsInput}"

	fi

	echo "${vlsReturn}"

}


##----------------------------------------------------------------------------------------------------
function fUnpackArgs_ToArrayPtr(){ :;
	##	Purpose:
	##		Unpacks args previously packed with fPackString(), into the named array.
	##	Arguments:
	##		- 1 [REQUIRED]: Packed args string.
	##		- 2 [REQUIRED]: The name of an array variable. Must be visible in scope to this function.
	##	Modifies:
	##		- Overwrites the named array.
	##	History:
	##		- 20180306 JC (0_library_v2): Created.

	## Arguments
	local packedArgs="$1"
	local arrayName="$2"

	## Variables
	#local -a tmpArray
	local packedArgsCount=0
	local arrayIndex=0
	local packedargsIndex=0
	local unpackedArg=""

	## Validate
	if [[ -z "$1" ]]; then _fThrowError "${meName}.${FUNCNAME[0]}(): First argument [packed args] can't be empty."; fi
	if [[ -z "$1" ]]; then _fThrowError "${meName}.${FUNCNAME[0]}(): First argument [name of target packed args variable] can't be empty."; fi

	## Initialize
	eval "${arrayName}=()"    ## Clear out the specified array.

	## Unpack and fill array
	packedArgsCount=$(fPackedArgs_GetCount "${packedArgs}")
	if [[ $packedArgsCount -gt 0 ]]; then :;
		for ((arrayIndex = 0; arrayIndex < $packedArgsCount; arrayIndex++)); do
			packedargsIndex=$(( arrayIndex+1 ))
			unpackedArg="$(fUnpackArg_Number "${packedArgs}" ${packedargsIndex})"
			eval "${arrayName}+=(\"${unpackedArg}\")"
		done
	fi

}


##----------------------------------------------------------------------------------------------------
function fPackArgs_FromArrayPtr(){ :;
	##	Purpose:
	##		Packs args from a named array.
	##	Arguments:
	##		- 1 [REQUIRED]: The name of an array variable. Must be visible in scope to this function.
	##		- 2 [REQUIRED]: The name of a packed-args variable. Must be visible in scope to this function.
	##	Modifies:
	##		- Overwrites value of specified packed args string.
	##	History:
	##		- 20180306 JC (0_library_v2): Created.

	## Arguments
	local arrayName="$1"
	local packedArgsVarName="$2"

	## Variables
	local -a tmpArray
	local tmpPackedArgs=""

	## Validate
	if [[ -z "$1" ]]; then _fThrowError "${meName}.${FUNCNAME[0]}(): First argument [name of source array variable] can't be empty."; fi
	if [[ -z "$1" ]]; then _fThrowError "${meName}.${FUNCNAME[0]}(): First argument [name of target packed args variable] can't be empty."; fi

	## Copy the array so we can access it directly
	tmpArray=()
	# shellcheck disable=1087
	eval "tmpArray=( \"\${$arrayName[@]}\" )"

	## Misc init
	eval "${packedArgsVarName}=\"\""

	### Debug
	#fEcho_Clean ""
	#fEcho_Clean	"tmpArray[] count ...: ${#tmpArray[@]}"
	#fEcho_Clean	"tmpArray[0] ........: '${tmpArray[0]}'"

	## Loop through the array
	local currentArg=""
	local currentArg_PackStrd=""
	local encodedPackStrs=""
	for currentArg in "${tmpArray[@]}"; do

		## Encode current item
		currentArg_PackStrd="$(fPackString "${currentArg}")"

		## Bundle packed strings together
		## if [[ -n "${encodedPackStrs}" ]]; then encodedPackStrs="${encodedPackStrs}_"; fi  ## 20190615 JC: Changed from _ to ☊ because _ was turning up in unpacked strings somehow. Not sure if this will fix it.
		if [[ -n "${encodedPackStrs}" ]]; then encodedPackStrs="${encodedPackStrs}☊"; fi
		encodedPackStrs="${encodedPackStrs}${currentArg_PackStrd}"

	done

	## Package them up in single packed args wrapper
	tmpPackedArgs="⦃packedargs-begin⦄${encodedPackStrs}⦃packedargs-end⦄"

	## Copy the value to the defined variable pointer
	eval "${packedArgsVarName}=\"${tmpPackedArgs}\""

}


##----------------------------------------------------------------------------------------------------
function fPackString(){ :;
	##	Purpose:
	##		Packs a string up to allow passing around to functions and scripts,
	##		withouting getting fubar'ed by spaces and quotes.
	##	Input:
	##		A string. Can contain spaces, single quotes, double quotes, etc.
	##	Note:
	##		Outer quotes will always be ignored. If you must get quotes preserved in a string,
	##		use single quotes with outer double quotes (e.g. "'first name' 'last name'"),
	##		double quotes with outer single quotes (e.g. '"first name" "last name"'),
	##		or escaped quotes if all the same (e.g. "\"first name\" \"last name\"").
	##	Returns via echo:
	##		A packed string that can be safely passed around without getting munged.
	##	History:
	##		- 20161003 JC (0_library_v1): Created.
	##		- 20161003 JC (0_library_v1):
	##			- Removed looping. Now explicitly just operates on the command argument as one big string.
	##			- Renamed from fArgs_Pack() to fPackString().
	##			- Updated "created" date from probably erroneous 2006, to 2016.
	##			- Updated comments.
	##			- Added outer "if" statement to catch null input.
	##		- 20171217 JC (0_library_v2):
	##			- Add packing header during packing process.
	##			- Check for packing header before packing, to avoid packing more than once.

	## Variables
	local vlsInput="$*"
	local vlsReturn=""

	if [[ "${vlsInput}" =~ ^⦃packedstring-begin⦄.*⦃packedstring-end⦄$ ]]; then  ##⦃⦄

		## Return already packed input
		vlsReturn="${vlsInput}"

	else :;
		if [[ -z "${vlsInput}" ]]; then :;

			## Explicitly empty
			vlsReturn="⦃empty⦄"

		else :;

			## Works
			vlsReturn="${vlsInput}"
			vlsReturn="$(echo "${vlsReturn}" | sed "s/\"/⦃dquote⦄/g" )"                               ## "    [double quote]
			vlsReturn="$(echo "${vlsReturn}" | sed "s/'/⦃squote⦄/g" )"                                ## '    [single quote]
			vlsReturn="${vlsReturn//$/⦃dollar⦄}"                                                      ## $    [dollar]
			vlsReturn="${vlsReturn//\%/⦃percent⦄}"                                                    ## %    [percent]
			vlsReturn="${vlsReturn//$'\n'/⦃newline⦄}"                                                 ## \n   [newline]
			vlsReturn="$(echo "${vlsReturn}" | sed 's#\t#⦃tab⦄#g' )"                                  ## \t   [tab]
			vlsReturn="$(echo "${vlsReturn}" | sed 's/ /⦃space⦄/g' )"                                 ## ' '  [space]
			vlsReturn="$(echo "${vlsReturn}" | sed 's#\\#⦃whack⦄#g' )"                                ## \    [whack]
			vlsReturn="$(echo "${vlsReturn}" | sed 's#\/#⦃slash⦄#g' )"                                ## /    [slash]
			vlsReturn="${vlsReturn//_/⦃underscore⦄}"                                                   ## _    [underscore]

			## Doesn't work
			#vlsReturn="$(echo "${vlsReturn}" | sed -e ":a" -e "N" -e "$!ba" -e "s/\n/⦃newline⦄/g" )"  ## \n   [newline]

		fi

		## Wrap with start and end wrappers
		vlsReturn="⦃packedstring-begin⦄${vlsReturn}⦃packedstring-end⦄"

	fi

	echo "${vlsReturn}"

}


##----------------------------------------------------------------------------------------------------
function fUnpackString(){ :;
	##	Purpose:
	##		Unpacks a string previously packed with fPackString(), into its original
	##		special characters.
	##	Arguments:
	##		- 1 [optional]: Packed arguments string originally generated by fPackString().
	##	Returns via echo:
	##		- Original string.
	##	History:
	##		- 20161003 JC (0_library_v1): Created.
	##		- 20161003 JC (0_library_v1):
	##			- Removed looping. Now explicitly just operates on the command argument as one big string.
	##			- Renamed from fArgs_Unpack() to fUnpackString().
	##			- Updated "created" date from probably erroneous 2006, to 2016.
	##			- Updated comments.
	##			- Added outer "if" statement to catch null input.
	##		- 20171217 JC (0_library_v2):
	##			- Check for packing header before unpacking, to avoid unpacking a non-packed args.
	##			- Remove packing header.

	## Variables.
	local vlsInput="$*"
	local vlsReturn=""

	if [[ -n "${vlsInput}" ]]; then :;

		if [[ "${vlsInput}" =~ ^⦃packedstring-begin⦄.*⦃packedstring-end⦄$ ]]; then :;

			## Strip off wrapper
			#vlsReturn="${vlsReturn/⦃packedstring-begin⦄/}"
			#vlsReturn="${vlsReturn/⦃packedstring-end⦄/}"
			vlsReturn="${vlsInput}"
			vlsReturn="$(echo "${vlsReturn}" | sed "s/⦃packedstring-begin⦄//g")"
			vlsReturn="$(echo "${vlsReturn}" | sed "s/⦃packedstring-end⦄//g")"

			## Check for empty
			if [[ "${vlsReturn}" == "⦃empty⦄" ]]; then :;
				vlsReturn=""
			else :;

				## Works
				vlsReturn="${vlsReturn//⦃underscore⦄/_}"                                                  ## _    [underscore]
				vlsReturn="${vlsReturn//⦃percent⦄/\%}"                                                    ## %    [percent]
				vlsReturn="${vlsReturn//⦃dollar⦄/$}"                                                      ## $    [dollar]
				vlsReturn="$(echo "${vlsReturn}" | sed 's/⦃space⦄/ /g' )"                                 ## ' '  [space]
				vlsReturn="$(echo "${vlsReturn}" | sed 's#⦃whack⦄#\\#g' )"                                ## \    [whack]
				vlsReturn="$(echo "${vlsReturn}" | sed 's#⦃slash⦄#\/#g' )"                                ## /    [slash]
				vlsReturn="$(echo "${vlsReturn}" | sed 's#⦃tab⦄#\t#g' )"                                  ## \t   [tab]
				vlsReturn="${vlsReturn/⦃newline⦄/$'\n'}"                                                  ## \n   [newline]
				vlsReturn="$(echo "${vlsReturn}" | sed "s/⦃squote⦄/'/g" )"                                ## '    [single quote]
				vlsReturn="$(echo "${vlsReturn}" | sed "s/⦃dquote⦄/\"/g" )"                               ## "    [double quote]

				## Doesn't work
				#vlsReturn="$(echo "${vlsReturn}" | sed -e ":a" -e "N" -e "$!ba" -e "s#⦃newline⦄#\n#g" )"  ## \n   [newline]

				## Ignore
				#vlsReturn="${vlsReturn/_27DKGA6-Underscore_/_}"                                                   ## _    [underscore]

			fi
		else :;

			## It is not packed, so return unchanged
			vlsReturn="${vlsInput}"

		fi
	fi

	echo "${vlsReturn}"
}








##############################################################################
##	Generic echo-related stuff.
##	History:
##		- 20190911 JC: Created (mostly by copying TEMPLATE_v*)
##############################################################################
declare -i _wasLastEchoBlank=0
function _fPipeAllRawStdout(){
	if [[ ${doDebug} -eq 1 ]] && [[ ${_dbgNestLevel} -ge 0 ]]; then
		## Send this to stdout before stdin; it indents each streaming line by (_dbgNestLevel *_dbgIndentEachLevelBy)
		sed "s/^/$(printf "%$((_dbgNestLevel * _dbgIndentEachLevelBy))s")/"
	else
		cat  ## Send stdin to stdout
	fi
}
function _fEcho_ResetBlankCounter(){ _wasLastEchoBlank=0; }
function _fEcho_Clean(){
	if [[ -n "$1" ]]; then
		#echo -e "$*" | fold -s -w $(tput cols)  ## Break on words, rather than arbitrarily.
		echo -e "$*" | _fPipeAllRawStdout
		_wasLastEchoBlank=0
	else
		if [[ $_wasLastEchoBlank -eq 0 ]]; then echo; fi
		_wasLastEchoBlank=1
	fi
}
function _fEcho(){
	if [[ -n "$*" ]]; then
		_fEcho_Clean "[ $* ]"
	else
		_fEcho_Clean ""
	fi
}
# shellcheck disable=2120  ## References arguments, but none are ever passed; Just because this library function isn't called here, doesn't mean it never will in other scripts.
function _fEcho_Force(){
	_fEcho_ResetBlankCounter
	_fEcho "$*"
}
function _fEcho_Clean_Force(){
	_fEcho_ResetBlankCounter
	_fEcho_Clean "$*"
}
function _fEchoVarAndVal(){
	local -r varName="$1"
	local -r optionalPrefix="$2"
	#_fEcho_Clean "$(_fStrJustify_byecho "${optionalPrefix}${varName}" "'${!varName}'")"
	_fEcho_Clean "${optionalPrefix}${varName} = '${!varName}'"
}


##############################################################################
##	Debugging/profiling-related stuff
##	History:
##		- 20190927 JC: Created.
##############################################################################
declare -i -r _dbgIndentEachLevelBy=4
declare -i    _dbgNestLevel=0
declare -i    _dbgTemporarilyDisableEcho=0
function _fdbgEnter(){
	if [[ ${doDebug} -eq 1 ]]; then
		local    -r functionName="$1"
		local    -r extraText="$2"
		local -i    dontEchoToStdout=0; if [[ -n "$3" ]] && [[ $3 =~ ^[0-9]+$ ]]; then dontEchoToStdout=$3; fi
		local       output=""

		## Output text to stdout
		if [[ -n "$functionName" ]]; then output=".$functionName()"; fi
		output="Entered ${meName}${output}"
		if [[ -n "$extraText" ]]; then output="$output [${extraText}]"; fi
		output="▶ $output:"
		if [[ $dontEchoToStdout -eq 0 ]]; then _fdbgEcho "${output}"; fi

		## Increment nest counter
		if [[ _dbgNestLevel -lt 0 ]]; then _dbgNestLevel=0; fi
		_dbgNestLevel=$((_dbgNestLevel+1))

	fi
}
function _fdbgEgress(){
	if [[ ${doDebug} -eq 1 ]]; then
		local    -r functionName="$1"
		local    -r extraText="$2"
		local -i    dontEchoToStdout=0; if [[ -n "$3" ]] && [[ $3 =~ ^[0-9]+$ ]]; then dontEchoToStdout=$3; fi
		local       output=""

		## Decrement nest counter
		_dbgNestLevel=$((_dbgNestLevel-1))
		if [[ _dbgNestLevel -lt 0 ]]; then _dbgNestLevel=0; fi

		## Output text to stdout
		if [[ -n "$functionName" ]]; then output=".$functionName()"; fi
		output="Egressed ${meName}${output}"
		if [[ -n "$extraText" ]]; then output="$output [${extraText}]"; fi
		output="◀ $output."
		if [[ $dontEchoToStdout -eq 0 ]]; then _fdbgEcho "$output"; fi

	fi
}
function _fdbgEcho(){
	if [[ ${doDebug} -eq 1 ]] && [[ $_dbgTemporarilyDisableEcho -ne 1 ]]; then
		_fEcho_Clean "$*"
	fi
}
function _fdbgEchoVarAndVal(){
	if [[ "${doDebug}" -eq 1 ]]; then
		local -r varName="$1"
		local -r optionalPrefix="$2"
		local    outputStr=""
		if [[ -n "$optionalPrefix" ]]; then outputStr="$optionalPrefix"; fi
		outputStr="${outputStr}${varName} = '${!varName}'"
		_fdbgEcho "$outputStr"
	fi
}

##############################################################################
##	Generic error-handling  stuff.
##	History
##		- 20190826 JC: Created by copying from 0_library_v2.
##		- 20190919 JC: Slight tweaks to improve newline output.
##############################################################################
declare -i _wasCleanupRun=0
function _fThrowError(){ _fdbgEnter "${FUNCNAME[0]}" "" 1;
	local errMsg="$*"
	if [[ -z "${errMsg}" ]]; then errMsg="An error occurred."; fi
	_fEcho_Clean
	_fEcho_Clean "${errMsg}"
	exit 1
_fdbgEgress "${FUNCNAME[0]}" "" 1; }
function _fTrap_Exit(){ _fdbgEnter "${FUNCNAME[0]}" "" 0;
	if [[ "${_wasCleanupRun}" == "0" ]]; then  ## String compare is less to fail than integer
		_wasCleanupRun=1
		_fSingleExitPoint "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
	fi
_fdbgEgress "${FUNCNAME[0]}" "" 0; }
function _fTrap_Error(){ _fdbgEnter "${FUNCNAME[0]}" "" 0;
	if [[ "${_wasCleanupRun}" == "0" ]]; then  ## String compare is less to fail than integer
		_wasCleanupRun=1
		_fEcho_ResetBlankCounter
		_fSingleExitPoint "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
	fi
_fdbgEgress "${FUNCNAME[0]}" "" 1; }
function _fSingleExitPoint(){ _fdbgEnter "${FUNCNAME[0]}" "" 0;
	local -r signal="$1";  shift || true
	local -r lineNum="$1"; shift || true
	local -r errNum="$1";  shift || true
	local -r errMsg="$*"
	if [[ "${signal}" == "INT" ]]; then
		_fEcho_Force
		_fEcho "User interrupted."
		fCleanup  ## User cleanup
		exit 1
	elif [[ "${errNum}" != "0" ]] && [[ "${errNum}" != "1" ]]; then  ## Clunky string compare is less likely to fail than integer
		_fEcho_Clean
		_fEcho_Clean "Signal .....: '${signal}'"
		_fEcho_Clean "Err# .......: '${errNum}'"
		_fEcho_Clean "Error ......: '${errMsg}'"
		_fEcho_Clean "At line# ...: '${lineNum}'"
		_fEcho_Clean
		fCleanup  ## User cleanup
	else
		fCleanup  ## User cleanup
	fi
_fdbgEgress "${FUNCNAME[0]}" "" 0; }
function fprivate_Trap_Error_Ignore(){ _fdbgEnter "${FUNCNAME[0]}" "" 0;
	true
_fdbgEgress "${FUNCNAME[0]}" "" 0; }
function fDefineTrap_Error_Fatal(){ _fdbgEnter "${FUNCNAME[0]}" "" 0;
	true
	trap '_fTrap_Error ERR     ${LINENO} $? $_' ERR
	set -e
_fdbgEgress "${FUNCNAME[0]}" "" 0; }
function fDefineTrap_Error_Ignore(){ _fdbgEnter "${FUNCNAME[0]}" "" 0;
	trap 'fprivate_Trap_Error_Ignore' ERR
	set +e
_fdbgEgress "${FUNCNAME[0]}" "" 0; }



##############################################################################
## Execution entry point (do not modify generic template
##############################################################################

## Define error and exit handling
fDefineTrap_Error_Fatal
trap '_fTrap_Error SIGHUP  ${LINENO} $? $_' SIGHUP
trap '_fTrap_Error SIGINT  ${LINENO} $? $_' SIGINT    ## CTRL+C
trap '_fTrap_Error SIGTERM ${LINENO} $? $_' SIGTERM
trap '_fTrap_Exit  EXIT    ${LINENO} $? $_' EXIT
trap '_fTrap_Exit  INT     ${LINENO} $? $_' INT
trap '_fTrap_Exit  TERM    ${LINENO} $? $_' TERM

declare    meName="$(basename "${0}")"
declare -i doSkipIntroStuff=0
declare -i doPackArgs=1
declare    tmpAllArgs=""

## Handle prompting for sudo
if [[ ${runAsSudo} -eq 1 ]] && [[ "$1" == "reran_withsudo" ]]; then
	_fdbgEcho "reran_withsudo"
	doPackArgs=0        ## Aleady Packed
	doSkipIntroStuff=1  ## AlreadyPrompted
	shift || true   ## get "reran_withsudo" off the arg stack
fi

## Pack up arguments because there will be too many to handle with $1-$9.
if [[ ${doPackArgs} -eq 1 ]]; then
	tmpAllArgs="$*"
	_fdbgEcho "Packing args ..."
	fDefineTrap_Error_Ignore
		exitVal=0
		declare -a argArray=()
		while [[ ${exitVal} -eq 0 ]]; do
			nextArg="$1"
			if [[ -n "${nextArg}" ]]; then argArray+=("${nextArg}"); fi
			shift; exitVal=$?
		done
	fDefineTrap_Error_Fatal
	fPackArgs_FromArrayPtr argArray packedArgs
else
	## Already packed previously
	packedArgs="$1"
	shift || true
	tmpAllArgs="$*"
fi

### Debug
#_fEchoVarAndVal packedArgs

_fdbgEnter
	if [[ $* =~ --(unittest|unitest|unit-test) ]]; then
		_fUnitTest "${tmpAllArgs}"
	else
		_fdbgEcho "About to call fMain()"
		fMain "${packedArgs}" "${tmpAllArgs}"
	fi
_fdbgEgress

exit 0