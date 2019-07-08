# urlencode <string>
# echo the string urlencoded
urlencode()
{
  for c in $(echo "$@" | sed 's/\(.\)/\1 /g;s/  /%%20 /g'); do
    [[ "$c" =~ [a-zA-Z0-9.~_-] ]] && printf "$c" || printf '%%%02X' "'$c"
  done
}
