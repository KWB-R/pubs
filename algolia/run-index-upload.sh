#!/usr/bin/env bash

while getopts "pf:a:k:n:u:" opt; do
  case $opt in
  # netlify
  p)
    #pip install --upgrade 'algoliasearch>=2.0,<3.0'
    # Environment variables below (except PWD) should be configured
    # in the section 'Build & deploy/Environment variables' of your site in Netlify;
    # Alternatively, the ALGOLIA_INDEX_NAME variable can be defined in the netlify.toml file.
    de_pubs_index_file="$PWD/$HUGO_DE_PUBS_INDEX_FILE"
    en_pubs_index_file="$PWD/$HUGO_EN_PUBS_INDEX_FILE"
    app_id="$ALGOLIA_APP_ID"
    admin_api_key="$ALGOLIA_ADMIN_API_KEY"
    de_pubs_index_name="$ALGOLIA_DE_PUBS_INDEX_NAME"
    en_pubs_index_name="$ALGOLIA_EN_PUBS_INDEX_NAME"
    ;;
  # local dev
  f)
    index_file="$OPTARG"
    ;;
  a)
    app_id="$OPTARG"
    ;;
  k)
    admin_api_key="$OPTARG"
    ;;
  n)
    index_name="$OPTARG"
    ;;
  u)
    base_url="$OPTARG"
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    ;;
  esac
done

python algolia/index-upload.py \
    -f "$de_pubs_index_file" \
    -a "$app_id" \
    -k "$admin_api_key" \
    -n "$de_pubs_index_name" \
    -u "$base_url"
    
python algolia/index-upload.py \
    -f "$en_pubs_index_file" \
    -a "$app_id" \
    -k "$admin_api_key" \
    -n "$en_pubs_index_name" \
    -u "$base_url"
