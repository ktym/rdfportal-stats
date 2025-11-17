# rdfportal-stats

## Usage

```
git clone https://github.com/rdfportal/rdfportal-config.git
ruby -d rdfportal-stats.rb | sort | uniq > rdfportal-stats.txt 2> rdfportal-stats.err
ruby rdfportal-stats-summary.rb rdfportal-stats.txt > rdfportal-stats-summary.txt
```

