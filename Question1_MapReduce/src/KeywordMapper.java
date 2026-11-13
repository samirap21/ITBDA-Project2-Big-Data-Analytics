
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.hadoop.io.BytesWritable;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;

public class KeywordMapper
        extends Mapper<NullWritable, BytesWritable, Text, IntWritable> {

    private Pattern keywordPattern;

    @Override
    protected void setup(Context context)
            throws IOException, InterruptedException {

        String keyword = context.getConfiguration().get("search.keyword");

        if (keyword == null || keyword.trim().isEmpty()) {
            throw new IOException("Search keyword must be provided.");
        }

        keywordPattern = Pattern.compile(
                "(?<![\\p{L}\\p{N}_])"
                + Pattern.quote(keyword)
                + "(?![\\p{L}\\p{N}_])",
                Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE
        );
    }

    @Override
    protected void map(NullWritable key, BytesWritable value,
                       Context context)
            throws IOException, InterruptedException {


        FileSplit split = (FileSplit) context.getInputSplit();
        String fileName = split.getPath().getName();

        String document = new String(
                value.getBytes(),
                0,
                value.getLength(),
                StandardCharsets.UTF_8
        );

        String[] lines = document.split("\\r\\n|\\n|\\r", -1);

        for (int row = 0; row < lines.length; row++) {

            Matcher matcher = keywordPattern.matcher(lines[row]);

            while (matcher.find()) {

                int column = matcher.start() + 1;

                context.write(
                        new Text(fileName + ":row=" + (row + 1)),
                        new IntWritable(column)
                );
            }
        }
    }
}
