
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

public class KeywordReducer
        extends Reducer<Text, IntWritable, Text, Text> {

    @Override
    protected void reduce(Text key,
                          Iterable<IntWritable> values,
                          Context context)
            throws IOException, InterruptedException {

        List<Integer> columns = new ArrayList<Integer>();

        for (IntWritable value : values) {
            columns.add(value.get());
        }

        Collections.sort(columns);

        // Combine the positions into one output value
        StringBuilder result = new StringBuilder("columns=");

        for (int i = 0; i < columns.size(); i++) {
            if (i > 0) {
                result.append(",");
            }
            result.append(columns.get(i));
        }

        context.write(key, new Text(result.toString()));
    }
}
