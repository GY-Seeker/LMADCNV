import argparse
import numpy as np
import pandas as pd

# read file, and # is comment
def pipline(path):
    df = pd.read_csv(path, sep='\t', comment='#', header=None)

    # ruler of col 9
    def parse_complex_field(field):
        if pd.isna(field):
            return {}
        pairs = str(field).split(';')
        result = {}
        for pair in pairs:
            if '=' in pair:
                key, value = pair.split('=', 1)
                result[key] = value
            else:
                result[pair] = None
        return result

    # apply
    df['parsed'] = df[8].apply(parse_complex_field)

    # concat the parsed and raw data
    parsed_df = pd.json_normalize(df['parsed'])
    # drop col
    result_df = pd.concat([df.drop(columns=[8, 'parsed']), parsed_df], axis=1)

    # output
    return result_df

def filter(df,sample,min_size=0):
    df = df[df['samples'].str.contains(sample,case=False)]
    df = df.dropna()
    df['outer_end'] = df['outer_end'].apply(np.uint32)
    df['outer_start'] = df['outer_start'].apply(np.uint32)
    df['outer_size'] = df['outer_end']-df['outer_start']
    df['inner_start'] = df['inner_start'].apply(np.uint32)
    df['inner_end'] = df['inner_end'].apply(np.uint32)
    df['outer_size'] = df['outer_end'] - df['outer_start']
    df['inner_size'] = df['inner_end'] - df['inner_start']
    df = df[df['inner_size']>min_size]
    df = df[df['outer_size'] > min_size]
    return df

def save_file(df,save_path='result.csv'):
    df.to_csv(save_path)

def main():
    parser = argparse.ArgumentParser(description="Process DGV data and filter by sample.")
    parser.add_argument('--path', type=str, required=True, help="Path to the input GFF file")
    parser.add_argument('--sample', type=str, required=True, help="Sample name to filter (e.g., NA12878)")
    parser.add_argument('--threshold', type=int, default=0, help="Threshold for filtering (default: 0)")
    parser.add_argument('--output', type=str, help="Output CSV filename (default: {sample}_groundTruth.csv)")

    args = parser.parse_args()

    df_cnv = pipline(args.path)
    sample_groundTruth = filter(df_cnv, args.sample, args.threshold)

    output_filename = args.output if args.output else f"{args.sample}_groundTruth.csv"
    save_file(sample_groundTruth, output_filename)

if __name__ == "__main__":
    main()