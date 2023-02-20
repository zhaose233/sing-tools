#!/bin/bash

echo $$ > $2
sing-box run -c $1  &> /dev/null
