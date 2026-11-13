
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class KeywordSearchDriver {

    public static void main(String[] args) throws Exception {

        if (args.length != 3) {
            System.err.println(
                "Usage: KeywordSearchDriver <keyword> <input> <output>"
            );
            System.exit(2);
        }

        String keyword = args[0].trim();

        if (keyword.isEmpty()) {
            System.err.println("Keyword cannot be empty.");
            System.exit(2);
        }

        // Hadoop configuration
        Configuration conf = new Configuration();
        conf.set("search.keyword", keyword);

        Job job = Job.getInstance(conf, "Keyword Search - " + keyword);

        job.setJarByClass(KeywordSearchDriver.class);

        job.setMapperClass(KeywordMapper.class);
        job.setReducerClass(KeywordReducer.class);

        job.setInputFormatClass(WholeFileInputFormat.class);

        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(IntWritable.class);

        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        job.setNumReduceTasks(1);

        FileInputFormat.addInputPath(job, new Path(args[1]));
        FileOutputFormat.setOutputPath(job, new Path(args[2]));

        // Execute the job
        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
