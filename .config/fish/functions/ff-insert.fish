function ff-insert
	set -l file (ff 2>/dev/null)
	test -z "$file"; and return
	commandline -i -- "$file"
end
