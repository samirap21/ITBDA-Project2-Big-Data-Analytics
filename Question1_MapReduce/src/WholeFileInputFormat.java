
import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.BytesWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.JobContext;
import org.apache.hadoop.mapreduce.RecordReader;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;

public class WholeFileInputFormat
        extends FileInputFormat<NullWritable, BytesWritable> {

    @Override
    protected boolean isSplitable(JobContext context, Path filename) {
        return false;
    }

    @Override
    public RecordReader<NullWritable, BytesWritable>
            createRecordReader(InputSplit split,
                               TaskAttemptContext context) {
        return new WholeFileRecordReader();
    }

    public static class WholeFileRecordReader
            extends RecordReader<NullWritable, BytesWritable> {

        private FileSplit fileSplit;
        private Configuration configuration;
        private BytesWritable value = new BytesWritable();
        private boolean processed = false;

        @Override
        public void initialize(InputSplit split,
                               TaskAttemptContext context) {
            fileSplit = (FileSplit) split;
            configuration = context.getConfiguration();
        }

        @Override
        public boolean nextKeyValue() throws IOException {

            if (processed) {
                return false;
            }

            Path path = fileSplit.getPath();
            FileSystem fs = path.getFileSystem(configuration);

            long fileLength = fileSplit.getLength();

            if (fileLength > Integer.MAX_VALUE) {
                throw new IOException("Input document is too large.");
            }

            byte[] data = new byte[(int) fileLength];

            try (FSDataInputStream input = fs.open(path)) {
                input.readFully(0, data);
            }

            value.set(data, 0, data.length);
            processed = true;

            return true;
        }

        @Override
        public NullWritable getCurrentKey() {
            return NullWritable.get();
        }

        @Override
        public BytesWritable getCurrentValue() {
            return value;
        }

        @Override
        public float getProgress() {
            return processed ? 1.0f : 0.0f;
        }

        @Override
        public void close() {
        }
    }
}
