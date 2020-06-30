# Common SH(/BASH) functions, to be sourced.
#
# This is part of the [MoVeDo](https://github.com/movedo) project.
# See LICENSE.md for copyright information.

# Exit immediately on each error and unset variable;
# see: https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
#set -Eeuo pipefail
set -Eeu

_error() {
	msg="$@"

	echo "$0: ERROR: $msg" 1>&2
	exit 1
}

_warning() {
	msg="$@"

	echo "$0: WARNING: $msg" 1>&2
}

_var_set() {
	set | grep '^'"$1"'=' > /dev/null
}

_set_if_unset() {
	_var_name="$1"
	shift
	if ! _var_set "$_var_name"
	then
		eval "$_var_name='$@'"
	fi
}

script_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
# Root of the local MoVeDo (doc build tool) root directory
_set_if_unset movedo_root_dir `cd "$script_dir/.."; pwd`
# Where to look for the Python panflute Pandoc filters
filters_dir="$movedo_root_dir/filters"
# The Projects root dir
_set_if_unset proj_dir `pwd`
# Root directory for all files created during the documentation build process
_set_if_unset build_dir_rel "build"
_set_if_unset build_dir "$proj_dir/$build_dir_rel"
# YAML meta-data, to be usedin the single, fused Markdown file as FrontMatter
_set_if_unset doc_meta_file "$proj_dir/doc.yml"
# BibTex meta-data, to be usedin the PDF output (optional)
_set_if_unset biblography_file "$proj_dir/citations.bib"
_set_if_unset templates_dir "$movedo_root_dir/templates"
# Root for all generated sources
# the original sources are copied in here too,
# and the documentation is actually built from here
_set_if_unset gen_src_dir "$build_dir/gen_sources"
# Index file(s) containing the Markdonw sources
# to be used for linearizing, in the correct order.
_set_if_unset index_md_file_name "index-md.txt"
_set_if_unset index_md_file_generated "$gen_src_dir/$index_md_file_name"
_set_if_unset index_md_file_manual "$proj_dir/$index_md_file_name"
# If the manually crafted file one is present,
# it has precedence over the generated one.
_set_if_unset index_md_file "`[ -f "$index_md_file_manual" ] && echo "$index_md_file_manual" || echo "$index_md_file_generated"`"
_set_if_unset html_dir "$build_dir/html"
_set_if_unset pdf_dir "$build_dir/pdf"
_set_if_unset single_md "$build_dir/doc.md"
_set_if_unset single_pdf "$pdf_dir/doc.pdf"
# Open results (like PDF files or index.html) with the systems default viewer/editor
# default: "no"
# set to any non empty value for "yes"
_set_if_unset OPEN_X11 ""

_check_tool() {
	tool="$@"

	if ! which "$tool" > /dev/null 2>&1
	then
		_error "'$tool' is not installed. Please install it manually, or run '`dirname $0`/setup'"
	fi
}

_check_tools() {
	tools="$@"

	for tool in $tools
	do
		_check_tool "$tool"
	done
}

_check_env() {

	if [ ! -e "$gen_src_dir" ]
	then
		_error "Generated sources dir not found, please run '`dirname $0`/generate'"
	fi
}

_is_deb() {
	which apt-get > /dev/null 2>&1 && echo "true" || echo "false"
}

_contains_word() {
	word="$1"
	shift
	str="$@"
	# we use printf instead of echo for better portability
	printf '%s' "$str" \
		| grep -q -e '\(^\|[ .,:;]\)'"$word"'\($\|[ .,:;]\)'
}

_permanently_add_to_path() {
	add_path="$1"
	# HACK We probably should not modify the users environment permanently and globally like that
	echo '' >> "$HOME/.profile"
	echo 'export PATH="$PATH:'"$add_path"'"' >> "$HOME/.profile"
	echo '' >> "$HOME/.profile"
	export PATH="$PATH:$add_path"
}

# If the `git` tool is installed, and we are inside a git repo,
# return the git commit description.
# Else, return "<UNKNOWN>".
_fetch_version() {
	doc_version="<UNKNOWN>"
	if which git &> /dev/null && git rev-parse --is-inside-work-tree &> /dev/null
	then
		doc_version="$(git describe --always --dirty)"
	fi
	echo "$doc_version"
}
